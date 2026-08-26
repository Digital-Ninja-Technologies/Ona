/// An AI-generated place recommendation for a location typed by the user,
/// as opposed to a [Destination]/[Experience] stored in the database.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.description,
    this.imageUrl,
  });

  final String name;
  final String description;

  /// A real photo found via Brave Image Search, attached server-side — the
  /// LLM is never asked to produce an image URL itself. Null if no image
  /// could be found (or the lookup failed) for this place.
  final String? imageUrl;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
