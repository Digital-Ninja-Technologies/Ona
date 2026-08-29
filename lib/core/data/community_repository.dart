import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/auth_controller.dart';
import '../models/community_post.dart';
import '../models/post_comment.dart';
import 'public_profiles_repository.dart';

class CommunityRepository {
  CommunityRepository(this._ref);

  final Ref _ref;

  String? get _userId => _ref.read(supabaseProvider).auth.currentUser?.id;

  /// Fetches the community feed, or (with [authorId]) just one user's own
  /// posts — used for both the main feed and a user's profile screen.
  Future<List<CommunityPost>> fetchPosts({
    String? type,
    String? authorId,
    int limit = 50,
  }) async {
    final client = _ref.read(supabaseProvider);
    var query = client.from('community_posts').select();
    if (type != null && type != 'all') {
      query = query.eq('type', type);
    }
    if (authorId != null) {
      query = query.eq('user_id', authorId);
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    final postRows = List<Map<String, dynamic>>.from(rows as List);
    if (postRows.isEmpty) return [];

    final authorIds = postRows.map((row) => row['user_id'] as String);
    final profiles = await fetchPublicProfiles(client, authorIds);

    var likedPostIds = <String>{};
    var repostedPostIds = <String>{};
    final userId = _userId;
    if (userId != null) {
      final postIds = postRows.map((row) => row['id'] as String).toList();
      final results = await Future.wait([
        client
            .from('post_likes')
            .select('post_id')
            .eq('user_id', userId)
            .inFilter('post_id', postIds),
        client
            .from('post_reposts')
            .select('post_id')
            .eq('user_id', userId)
            .inFilter('post_id', postIds),
      ]);
      likedPostIds = List<Map<String, dynamic>>.from(
        results[0] as List,
      ).map((row) => row['post_id'] as String).toSet();
      repostedPostIds = List<Map<String, dynamic>>.from(
        results[1] as List,
      ).map((row) => row['post_id'] as String).toSet();
    }

    final quotedPostIds = postRows
        .map((row) => row['quoted_post_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final quotedPosts = quotedPostIds.isEmpty
        ? <String, CommunityPost>{}
        : await _fetchPostsByIds(client, quotedPostIds);

    return postRows.map((row) {
      final id = row['id'] as String;
      return CommunityPost.fromJson(
        row,
        author: profileOrFallback(profiles, row['user_id'] as String),
        isLikedByMe: likedPostIds.contains(id),
        isRepostedByMe: repostedPostIds.contains(id),
        quotedPost: quotedPosts[row['quoted_post_id'] as String?],
      );
    }).toList();
  }

  /// Fetches a flat batch of posts by id (author-enriched, but with no
  /// like/repost/quote state of their own) — used to resolve the quoted
  /// post embedded in a quote-repost, one level deep only.
  Future<Map<String, CommunityPost>> _fetchPostsByIds(
    SupabaseClient client,
    List<String> ids,
  ) async {
    final rows = await client
        .from('community_posts')
        .select()
        .inFilter('id', ids);
    final postRows = List<Map<String, dynamic>>.from(rows as List);
    if (postRows.isEmpty) return {};
    final authorIds = postRows.map((row) => row['user_id'] as String);
    final profiles = await fetchPublicProfiles(client, authorIds);
    return {
      for (final row in postRows)
        row['id'] as String: CommunityPost.fromJson(
          row,
          author: profileOrFallback(profiles, row['user_id'] as String),
        ),
    };
  }

  /// Fetches one post by id, fully enriched (like/repost state, quoted-post
  /// embed) the same way [fetchPosts] rows are — used to show the post
  /// itself above its comment thread, and when a notification deep-links to
  /// a specific post. Null if it no longer exists.
  Future<CommunityPost?> fetchPostById(String postId) async {
    final client = _ref.read(supabaseProvider);
    final row = await client
        .from('community_posts')
        .select()
        .eq('id', postId)
        .maybeSingle();
    if (row == null) return null;

    final profiles = await fetchPublicProfiles(client, [
      row['user_id'] as String,
    ]);

    var isLiked = false;
    var isReposted = false;
    final userId = _userId;
    if (userId != null) {
      final results = await Future.wait([
        client
            .from('post_likes')
            .select('post_id')
            .eq('user_id', userId)
            .eq('post_id', postId),
        client
            .from('post_reposts')
            .select('post_id')
            .eq('user_id', userId)
            .eq('post_id', postId),
      ]);
      isLiked = (results[0] as List).isNotEmpty;
      isReposted = (results[1] as List).isNotEmpty;
    }

    final quotedPostId = row['quoted_post_id'] as String?;
    CommunityPost? quotedPost;
    if (quotedPostId != null) {
      final quoted = await _fetchPostsByIds(client, [quotedPostId]);
      quotedPost = quoted[quotedPostId];
    }

    return CommunityPost.fromJson(
      row,
      author: profileOrFallback(profiles, row['user_id'] as String),
      isLikedByMe: isLiked,
      isRepostedByMe: isReposted,
      quotedPost: quotedPost,
    );
  }

  Future<void> createPost({
    required String type,
    required String content,
    String? imageUrl,
    String? destinationId,
    String? quotedPostId,
  }) async {
    final client = _ref.read(supabaseProvider);
    await client.from('community_posts').insert({
      'user_id': _userId,
      'type': type,
      'content': content,
      'image_url': imageUrl,
      'destination_id': destinationId,
      'quoted_post_id': quotedPostId,
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

  /// Toggles a repost ("retweet") of [postId] for the signed-in user.
  Future<void> setReposted(String postId, bool reposted) async {
    final client = _ref.read(supabaseProvider);
    final userId = _userId;
    if (userId == null) return;
    if (reposted) {
      await client.from('post_reposts').insert({
        'post_id': postId,
        'user_id': userId,
      });
    } else {
      await client
          .from('post_reposts')
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
        // order()'s `ascending` defaults to false in this postgrest-dart
        // version — without this, comments render newest-first.
        .order('created_at', ascending: true);
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
    String? parentCommentId,
  }) async {
    final client = _ref.read(supabaseProvider);
    await client.from('post_comments').insert({
      'post_id': postId,
      'user_id': _userId,
      'content': content,
      'parent_comment_id': parentCommentId,
    });
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref);
});

final postTypeFilterProvider = StateProvider<String>((ref) => 'all');

/// Post ids with a like toggle currently in flight — used to disable the
/// like button mid-request so a fast double-tap can't race two writes for
/// the same post and hit the post_likes primary key.
final likeTogglingProvider = StateProvider<Set<String>>((ref) => {});

/// Same in-flight guard as [likeTogglingProvider], for reposts.
final repostTogglingProvider = StateProvider<Set<String>>((ref) => {});

final communityPostsProvider = FutureProvider.autoDispose<List<CommunityPost>>((
  ref,
) {
  final type = ref.watch(postTypeFilterProvider);
  return ref.watch(communityRepositoryProvider).fetchPosts(type: type);
});

final postCommentsProvider = FutureProvider.autoDispose
    .family<List<PostComment>, String>((ref, postId) {
      return ref.watch(communityRepositoryProvider).fetchComments(postId);
    });

/// One user's own posts, for their profile screen.
final userPostsProvider = FutureProvider.autoDispose
    .family<List<CommunityPost>, String>((ref, userId) {
      return ref
          .watch(communityRepositoryProvider)
          .fetchPosts(authorId: userId);
    });

/// A single post, enriched the same way feed rows are — shown above its
/// comment thread and used for notification deep links.
final singlePostProvider = FutureProvider.autoDispose
    .family<CommunityPost?, String>((ref, postId) {
      return ref.watch(communityRepositoryProvider).fetchPostById(postId);
    });
