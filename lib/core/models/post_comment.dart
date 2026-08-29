import 'public_profile.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
  });

  final String id;
  final String postId;
  final PublicProfile author;
  final String content;
  final DateTime createdAt;

  /// Null for a top-level comment. Otherwise the id of the root comment this
  /// is a reply to — replying to a reply still points here (flattened to
  /// one level; see the 0005_comment_replies migration), not at the reply
  /// itself.
  final String? parentCommentId;

  bool get isReply => parentCommentId != null;

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
      parentCommentId: json['parent_comment_id'] as String?,
    );
  }
}
