import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/community_post.dart';
import '../models/post_comment.dart';
import 'public_profiles_repository.dart';

class CommunityRepository {
  CommunityRepository(this._ref);

  final Ref _ref;

  String? get _userId =>
      _ref.read(supabaseProvider).auth.currentUser?.id;

  Future<List<CommunityPost>> fetchPosts({String? type, int limit = 50}) async {
    final client = _ref.read(supabaseProvider);
    var query = client.from('community_posts').select();
    if (type != null && type != 'all') {
      query = query.eq('type', type);
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    final postRows = List<Map<String, dynamic>>.from(rows as List);
    if (postRows.isEmpty) return [];

    final authorIds = postRows.map((row) => row['user_id'] as String);
    final profiles = await fetchPublicProfiles(client, authorIds);

    var likedPostIds = <String>{};
    final userId = _userId;
    if (userId != null) {
      final postIds = postRows.map((row) => row['id'] as String).toList();
      final likeRows = await client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId)
          .inFilter('post_id', postIds);
      likedPostIds = List<Map<String, dynamic>>.from(likeRows as List)
          .map((row) => row['post_id'] as String)
          .toSet();
    }

    return postRows.map((row) {
      final id = row['id'] as String;
      return CommunityPost.fromJson(
        row,
        author: profileOrFallback(profiles, row['user_id'] as String),
        isLikedByMe: likedPostIds.contains(id),
      );
    }).toList();
  }

  Future<void> createPost({
    required String type,
    required String content,
    String? imageUrl,
    String? destinationId,
  }) async {
    final client = _ref.read(supabaseProvider);
    await client.from('community_posts').insert({
      'user_id': _userId,
      'type': type,
      'content': content,
      'image_url': imageUrl,
      'destination_id': destinationId,
    });
  }

  Future<void> deletePost(String postId) async {
    final client = _ref.read(supabaseProvider);
    await client.from('community_posts').delete().eq('id', postId);
  }

  Future<void> setLiked(String postId, bool liked) async {
    final client = _ref.read(supabaseProvider);
    final userId = _userId;
    if (userId == null) return;
    if (liked) {
      await client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    } else {
      await client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    final client = _ref.read(supabaseProvider);
    final rows = await client
        .from('post_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at');
    final commentRows = List<Map<String, dynamic>>.from(rows as List);
    if (commentRows.isEmpty) return [];
    final authorIds = commentRows.map((row) => row['user_id'] as String);
    final profiles = await fetchPublicProfiles(client, authorIds);
    return commentRows
        .map(
          (row) => PostComment.fromJson(
            row,
            author: profileOrFallback(profiles, row['user_id'] as String),
          ),
        )
        .toList();
  }

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final client = _ref.read(supabaseProvider);
    await client.from('post_comments').insert({
      'post_id': postId,
      'user_id': _userId,
      'content': content,
    });
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref);
});

final postTypeFilterProvider = StateProvider<String>((ref) => 'all');

final communityPostsProvider = FutureProvider.autoDispose<List<CommunityPost>>(
  (ref) {
    final type = ref.watch(postTypeFilterProvider);
    return ref.watch(communityRepositoryProvider).fetchPosts(type: type);
  },
);

final postCommentsProvider = FutureProvider.autoDispose
    .family<List<PostComment>, String>((ref, postId) {
      return ref.watch(communityRepositoryProvider).fetchComments(postId);
    });
