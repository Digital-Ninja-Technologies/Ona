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
    this.repostsCount = 0,
    required this.createdAt,
    this.isLikedByMe = false,
    this.isRepostedByMe = false,
    this.quotedPost,
  });

  final String id;
  final PublicProfile author;
  final String type;
  final String content;
  final String? imageUrl;
  final String? destinationId;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final DateTime createdAt;
  final bool isLikedByMe;
  final bool isRepostedByMe;

  /// The post this one quote-reposts, if any — fetched one level deep only
  /// (a quoted post's own [quotedPost] is always null, so quote chains
  /// don't recurse indefinitely). Null if this isn't a quote post, or if
  /// the quoted post has since been deleted.
  final CommunityPost? quotedPost;

  CommunityPost copyWith({
    int? likesCount,
    bool? isLikedByMe,
    int? repostsCount,
    bool? isRepostedByMe,
  }) {
    return CommunityPost(
      id: id,
      author: author,
      type: type,
      content: content,
      imageUrl: imageUrl,
      destinationId: destinationId,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      createdAt: createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isRepostedByMe: isRepostedByMe ?? this.isRepostedByMe,
      quotedPost: quotedPost,
    );
  }

  factory CommunityPost.fromJson(
    Map<String, dynamic> json, {
    required PublicProfile author,
    bool isLikedByMe = false,
    bool isRepostedByMe = false,
    CommunityPost? quotedPost,
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
      repostsCount: (json['reposts_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      isLikedByMe: isLikedByMe,
      isRepostedByMe: isRepostedByMe,
      quotedPost: quotedPost,
    );
  }
}
