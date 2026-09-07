import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/place_category.dart';
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

  /// Fetches AI-generated suggestions for a [location] the user typed
  /// manually — used when the app has no database destination matching it.
  /// These are spots *within* the location, of the kind set by [category]:
  /// attractions by default, or hotels, restaurants, nightlife, etc.
  Future<List<PlaceSuggestion>> fetchPlaces(
    String location, {
    PlaceCategory category = PlaceCategory.attractions,
  }) {
    return _fetchStructuredPlaces(
      'List ${category.promptNoun} in $location.',
    );
  }

  /// Fetches another batch of suggestions for [location] / [category], for a
  /// "More" button under an existing [fetchPlaces] list. [exclude] is the
  /// names already shown, so the model doesn't just repeat them.
  Future<List<PlaceSuggestion>> fetchMorePlaces(
    String location, {
    required List<String> exclude,
    PlaceCategory category = PlaceCategory.attractions,
  }) {
    final excludeClause = exclude.isEmpty
        ? ''
        : ' Do not repeat any of these already-shown places: '
              '${exclude.join(', ')}.';
    return _fetchStructuredPlaces(
      'List more ${category.promptNoun} in $location, different from what '
      "you'd typically suggest first.$excludeClause",
    );
  }

  /// Fetches AI-generated nearby *destinations* worth traveling to from
  /// [location] — other cities/regions within reach, not attractions inside
  /// [location] itself (contrast with [fetchPlaces]). Used to populate
  /// "Popular Destinations" from the user's geolocation.
  Future<List<PlaceSuggestion>> fetchNearbyDestinations(String location) {
    return _fetchStructuredPlaces(
      'List popular travel destinations worth visiting near $location.',
    );
  }

  /// Resolves one specific named place — e.g. an itinerary activity like
  /// "Visit the Louvre Museum" — into a full [PlaceSuggestion], used to link
  /// itinerary activities to the place detail screen. [query] should
  /// include enough context to disambiguate (activity text plus
  /// destination). Returns null if the AI couldn't identify a real place.
  Future<PlaceSuggestion?> lookupPlace(String query) async {
    final client = _ref.read(supabaseProvider);
    final response = await client.functions.invoke(
      'ai-assistant',
      body: {'message': query, 'singlePlace': true},
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data is! Map || data['reply'] is! String) {
      throw Exception('Unexpected response from ai-assistant.');
    }

    var raw = (data['reply'] as String).trim();
    if (raw.startsWith('```')) {
      raw = raw
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected place format from ai-assistant.');
    }
    final place = PlaceSuggestion.fromJson(decoded);
    return place.name.isEmpty ? null : place;
  }

  /// Calls `ai-assistant` with `structuredPlaces: true`, which returns
  /// `reply` as a JSON array instead of chat prose, for [message]. Throws if
  /// the function errors or the reply isn't valid, parseable JSON.
  Future<List<PlaceSuggestion>> _fetchStructuredPlaces(String message) async {
    final client = _ref.read(supabaseProvider);
    final response = await client.functions.invoke(
      'ai-assistant',
      body: {'message': message, 'structuredPlaces': true},
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

/// The (location, category) pair a home-screen place lookup is keyed by, so
/// re-searching the same location + category reuses the cached result.
typedef PlacesQuery = ({String location, PlaceCategory category});

/// AI-generated suggestions for a manually-typed location and a chosen
/// [PlaceCategory] (attractions, hotels, restaurants, …).
final placesForLocationProvider = FutureProvider.family
    .autoDispose<List<PlaceSuggestion>, PlacesQuery>((ref, query) {
      return ref
          .watch(aiAssistantRepositoryProvider)
          .fetchPlaces(query.location, category: query.category);
    });
