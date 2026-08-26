import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/place_suggestion.dart';

class AiAssistantReply {
  const AiAssistantReply({required this.text, required this.interactionId});

  final String text;
  final String? interactionId;
}

class AiAssistantRepository {
  AiAssistantRepository(this._ref);

  final Ref _ref;

  /// Sends one chat turn to the `ai-assistant` Supabase Edge Function, which
  /// proxies to the Gemini API using a server-side secret. Gemini tracks
  /// conversation state server-side, so [message] and the
  /// [previousInteractionId] from the prior turn (null on the first turn)
  /// are normally enough. [history] (oldest first, ending with [message]) is
  /// sent too, purely as a fallback: if Gemini's free-tier quota is hit, the
  /// function falls back to Groq, which has no server-side memory and needs
  /// the full conversation to answer with context. Throws if the function
  /// hasn't been deployed / configured with GEMINI_API_KEY.
  Future<AiAssistantReply> sendMessage(
    String message, {
    String? previousInteractionId,
    List<Map<String, String>> history = const [],
  }) async {
    final client = _ref.read(supabaseProvider);
    final response = await client.functions.invoke(
      'ai-assistant',
      body: {
        'message': message,
        'previousInteractionId': previousInteractionId,
        'history': history,
      },
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data is! Map || data['reply'] is! String) {
      throw Exception('Unexpected response from ai-assistant.');
    }
    return AiAssistantReply(
      text: data['reply'] as String,
      interactionId: data['interactionId'] as String?,
    );
  }

  /// Fetches AI-generated place suggestions for a [location] the user typed
  /// manually — used when the app has no database destination matching it.
  /// Calls `ai-assistant` with `structuredPlaces: true`, which returns
  /// `reply` as a JSON array instead of chat prose. Throws if the function
  /// errors or the reply isn't valid, parseable JSON.
  Future<List<PlaceSuggestion>> fetchPlaces(String location) async {
    final client = _ref.read(supabaseProvider);
    final response = await client.functions.invoke(
      'ai-assistant',
      body: {
        'message': 'List nice places to visit in $location.',
        'structuredPlaces': true,
      },
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data is! Map || data['reply'] is! String) {
      throw Exception('Unexpected response from ai-assistant.');
    }

    // Models occasionally wrap JSON in a markdown code fence despite being
    // told not to — strip it defensively before parsing.
    var raw = (data['reply'] as String).trim();
    if (raw.startsWith('```')) {
      raw = raw
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw Exception('Unexpected places format from ai-assistant.');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PlaceSuggestion.fromJson)
        .where((place) => place.name.isNotEmpty)
        .toList();
  }
}

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepository(ref);
});

/// AI-generated places for a manually-typed location, keyed by the trimmed
/// location string so re-searching the same text reuses the cached result.
final placesForLocationProvider = FutureProvider.family
    .autoDispose<List<PlaceSuggestion>, String>((ref, location) {
      return ref.watch(aiAssistantRepositoryProvider).fetchPlaces(location);
    });
