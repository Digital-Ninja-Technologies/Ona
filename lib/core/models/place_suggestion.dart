/// An AI-generated place recommendation for a location typed by the user,
/// as opposed to a [Destination]/[Experience] stored in the database.
class PlaceSuggestion {
  const PlaceSuggestion({required this.name, required this.description});

  final String name;
  final String description;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
