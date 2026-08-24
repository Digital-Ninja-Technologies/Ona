import 'public_profile.dart';

class Review {
  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.comment,
    this.images = const [],
    required this.createdAt,
  });

  final String id;
  final PublicProfile author;
  final int rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;

  factory Review.fromJson(
    Map<String, dynamic> json, {
    required PublicProfile author,
  }) {
    return Review(
      id: json['id'] as String,
      author: author,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String,
      images: List<String>.from(json['images'] as List? ?? const []),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
