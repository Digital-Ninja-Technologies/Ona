import 'public_profile.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final PublicProfile author;
  final String content;
  final DateTime createdAt;

  factory PostComment.fromJson(
    Map<String, dynamic> json, {
    required PublicProfile author,
  }) {
    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      author: author,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
