import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/place_category.dart';
import '../models/place_suggestion.dart';
import '../models/travel_info.dart';

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

  /// A local food guide for [location] — must-try dishes, local drinks, and
  /// dining tips, grounded in live web results.
  Future<FoodGuide> fetchFoodGuide(String location) async {
    final json = await _fetchStructuredInfo(
      'Give a local food guide for $location. Respond with ONLY a JSON '
      'object shaped {"summary": string, "dishes": [{"name": string, '
      '"description": string, "whereToTry": string}], "drinks": [{"name": '
      'string, "description": string}], "tips": [string]}. Include 6 to 8 '
      'must-try local dishes (with a specific well-known restaurant, market '
      'or street-food area to try each), 2 to 4 notable local drinks, and 3 '
      'to 5 practical dining tips covering meal times, tipping, street-food '
      'safety and etiquette.',
    );
    return FoodGuide.fromJson(json);
  }

  /// A guide to getting mobile data in [location] as a traveler — local
  /// carriers, eSIM options, current prices, and where to buy.
  Future<SimGuide> fetchSimGuide(String location) async {
    final json = await _fetchStructuredInfo(
      'Give a guide to getting a tourist mobile data plan in $location. '
      'Respond with ONLY a JSON object shaped {"summary": string, '
      '"options": [{"provider": string, "type": string, "typicalPrice": '
      'string, "notes": string}], "whereToBuy": [string], "tips": '
      '[string]}. Cover the main local carriers and any reputable eSIM '
      'options, where "type" is "Physical SIM" or "eSIM" and "typicalPrice" '
      'is the current approximate cost of a typical tourist data package '
      '(state the local currency). List where to buy (airport, carrier '
      'shops, convenience stores, online) and setup tips such as passport '
      'or SIM-registration requirements and coverage.',
    );
    return SimGuide.fromJson(json);
  }

  /// Tourist visa requirements for a [fromCountry] passport holder
  /// travelling to [toCountry], grounded in current published rules.
  Future<VisaRequirement> fetchVisaRequirement({
    required String fromCountry,
    required String toCountry,
  }) async {
    final json = await _fetchStructuredInfo(
      'A traveler holding a passport from $fromCountry wants to visit '
      '$toCountry for tourism. Respond with ONLY a JSON object shaped '
      '{"requirement": string, "summary": string, "allowedStay": string, '
      '"cost": string, "processingTime": string, "howToApply": string, '
      '"documents": [string], "notes": [string]}. "requirement" must be '
      'exactly one of "Visa-free", "Visa on arrival", "eVisa", "Visa '
      'required" or "Unknown". Base every field on the current published '
      'rules in the search results; "notes" should flag things like '
      'passport validity, onward-ticket or funds requirements, and recent '
      'changes.',
    );
    return VisaRequirement.fromJson(json);
  }

  /// Calls `ai-assistant` with `structuredInfo: true` and returns the
  /// parsed JSON object from `reply`. Throws if the function errors or the
  /// reply isn't a parseable JSON object.
  Future<Map<String, dynamic>> _fetchStructuredInfo(String message) async {
    final client = _ref.read(supabaseProvider);
    final response = await client.functions.invoke(
      'ai-assistant',
      body: {'message': message, 'structuredInfo': true},
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
      throw Exception('Unexpected response format from ai-assistant.');
    }
    return decoded;
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

/// Local food guide for a location, keyed by the trimmed location string.
final foodGuideProvider = FutureProvider.family
    .autoDispose<FoodGuide, String>((ref, location) {
      return ref.watch(aiAssistantRepositoryProvider).fetchFoodGuide(location);
    });

/// Local SIM / eSIM guide for a location, keyed by the trimmed location.
final simGuideProvider = FutureProvider.family.autoDispose<SimGuide, String>((
  ref,
  location,
) {
  return ref.watch(aiAssistantRepositoryProvider).fetchSimGuide(location);
});

/// The passport / destination pair a visa lookup is keyed by.
typedef VisaQuery = ({String fromCountry, String toCountry});

/// Tourist visa requirements for a (passport country, destination country)
/// pair, keyed so re-checking the same pair reuses the result.
final visaRequirementProvider = FutureProvider.family
    .autoDispose<VisaRequirement, VisaQuery>((ref, query) {
      return ref
          .watch(aiAssistantRepositoryProvider)
          .fetchVisaRequirement(
            fromCountry: query.fromCountry,
            toCountry: query.toCountry,
          );
    });
