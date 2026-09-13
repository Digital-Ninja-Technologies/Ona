import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

/// Forward geocoding (address/place name -> coordinates) via the device's
/// native geocoder — the same one [LocationRepository] uses in reverse, so
/// no separate API key is needed. Used to plot a [PlaceSuggestion] (which
/// only ever has a free-text address, never coordinates) on [PlaceMap].
class GeocodingRepository {
  final _geocoding = Geocoding();

  /// Resolves [query] (e.g. "Golden Gate Bridge, San Francisco, CA") to a
  /// coordinate, or null if the geocoder found nothing / the lookup failed.
  Future<LatLng?> locate(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    try {
      final results = await _geocoding.locationFromAddress(trimmed);
      if (results.isEmpty) return null;
      final first = results.first;
      return LatLng(first.latitude, first.longitude);
    } catch (_) {
      // No geocoder present, network hiccup, address not found, etc. — the
      // map preview just stays hidden rather than showing an error.
      return null;
    }
  }
}

final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) {
  return GeocodingRepository();
});

/// Coordinates for a free-text place query, memoised per query string.
final placeCoordinatesProvider = FutureProvider.family<LatLng?, String>((
  ref,
  query,
) {
  return ref.watch(geocodingRepositoryProvider).locate(query);
});
