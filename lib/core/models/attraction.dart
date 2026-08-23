class Attraction {
  const Attraction({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.rating,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? description;
  final double? rating;

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}
