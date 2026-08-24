import 'public_profile.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.type,
    required this.content,
    this.imageUrl,
    this.destinationId,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.isLikedByMe = false,
  });

  final String id;
  final PublicProfile author;
  final String type;
  final String content;
  final String? imageUrl;
  final String? destinationId;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool isLikedByMe;

  CommunityPost copyWith({int? likesCount, bool? isLikedByMe}) {
    return CommunityPost(
      id: id,
      author: author,
      type: type,
      content: content,
      imageUrl: imageUrl,
      destinationId: destinationId,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      createdAt: createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  factory CommunityPost.fromJson(
    Map<String, dynamic> json, {
    required PublicProfile author,
    bool isLikedByMe = false,
  }) {
    return CommunityPost(
      id: json['id'] as String,
      author: author,
      type: json['type'] as String? ?? 'story',
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      destinationId: json['destination_id'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      isLikedByMe: isLikedByMe,
    );
  }
}
