import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place_suggestion.dart';

/// Persists the last "Popular Destinations" AI lookup to local storage
/// (SharedPreferences), keyed by the location it was generated for. Lets the
/// home screen show results instantly on the next launch without an AI call
/// when the user's resolved location hasn't changed, and tells it when a
/// refresh is actually needed because the location did change.
class NearbyDestinationsCache {
  static const _locationKey = 'nearby_destinations_location';
  static const _destinationsKey = 'nearby_destinations_list';

  Future<String?> readLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locationKey);
  }

  Future<List<PlaceSuggestion>?> readDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_destinationsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PlaceSuggestion.fromJson)
          .toList();
    } catch (_) {
      // Corrupt/old cache shape — treat as a cache miss rather than crash.
      return null;
    }
  }

  Future<void> save(String location, List<PlaceSuggestion> destinations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationKey, location);
    await prefs.setString(
      _destinationsKey,
      jsonEncode(
        destinations
            .map(
              (p) => {
                'name': p.name,
                'description': p.description,
                'imageUrl': p.imageUrl,
                'address': p.address,
                'phone': p.phone,
                'website': p.website,
                'reviews': p.reviews.map((r) => r.toJson()).toList(),
              },
            )
            .toList(),
      ),
    );
  }
}

final nearbyDestinationsCacheProvider = Provider<NearbyDestinationsCache>((
  ref,
) {
  return NearbyDestinationsCache();
});
