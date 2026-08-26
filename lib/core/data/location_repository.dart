import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationRepository {
  final _geocoding = Geocoding();

  /// Resolves the device's current city/country as a human-readable string
  /// (e.g. "Lagos, Nigeria"), suitable for feeding into the AI places
  /// lookup. Throws with a plain-language message if location services are
  /// off, permission is denied, or no placemark can be resolved.
  Future<String> fetchCurrentLocationName() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Turn on location services to use this.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission was denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final placemarks = await _geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) {
      throw Exception("Couldn't determine your city from your location.");
    }

    final place = placemarks.first;
    final city = place.locality?.trim();
    final country = place.country?.trim();
    if (city != null && city.isNotEmpty) {
      return country != null && country.isNotEmpty ? '$city, $country' : city;
    }
    if (country != null && country.isNotEmpty) return country;
    throw Exception("Couldn't determine your city from your location.");
  }
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});
