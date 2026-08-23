class Experience {
  const Experience({
    required this.id,
    required this.title,
    this.destinationId,
    this.description,
    this.imageUrl,
    this.category,
    this.price = 0,
    this.durationHours,
    this.maxParticipants,
    this.rating,
  });

  final String id;
  final String title;
  final String? destinationId;
  final String? description;
  final String? imageUrl;
  final String? category;
  final double price;
  final double? durationHours;
  final int? maxParticipants;
  final double? rating;

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] as String,
      title: json['title'] as String,
      destinationId: json['destination_id'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}
