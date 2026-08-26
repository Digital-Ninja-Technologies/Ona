import 'place_review.dart';

/// An AI-generated place recommendation for a location typed by the user,
/// as opposed to a [Destination]/[Experience] stored in the database.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.description,
    this.imageUrl,
    this.address,
    this.phone,
    this.website,
    this.reviews = const [],
  });

  final String name;
  final String description;

  /// A real photo found via Brave Image Search, attached server-side — the
  /// LLM is never asked to produce an image URL itself. Null if no image
  /// could be found (or the lookup failed) for this place.
  final String? imageUrl;

  /// A short human-readable address/locality for this place, as suggested
  /// by the LLM. Null for older cached entries saved before this field
  /// existed, or if the model didn't provide one.
  final String? address;

  /// Best-guess contact phone number for this place, as suggested by the
  /// LLM. Null for older cached entries, or if none is known.
  final String? phone;

  /// Best-guess official website for this place, as suggested by the LLM.
  /// Null for older cached entries, or if none is known.
  final String? website;

  /// Review snippets pulled from the web for this place — see [PlaceReview].
  /// Empty for older cached entries, or if none were found.
  final List<PlaceReview> reviews;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PlaceReview.fromJson)
              .toList() ??
          const [],
    );
  }
}
