class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.country,
    this.city,
    this.description,
    this.imageUrl,
    this.category = const [],
    this.rating,
    this.priceRange,
    this.bestTimeToVisit,
    this.popularActivities = const [],
  });

  final String id;
  final String name;
  final String country;
  final String? city;
  final String? description;
  final String? imageUrl;
  final List<String> category;
  final double? rating;
  final String? priceRange;
  final String? bestTimeToVisit;
  final List<String> popularActivities;

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      city: json['city'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      category: List<String>.from(json['category'] as List? ?? const []),
      rating: (json['rating'] as num?)?.toDouble(),
      priceRange: json['price_range'] as String?,
      bestTimeToVisit: json['best_time_to_visit'] as String?,
      popularActivities: List<String>.from(
        json['popular_activities'] as List? ?? const [],
      ),
    );
  }
}
