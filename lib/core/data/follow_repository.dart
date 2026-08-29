import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';

class FollowRepository {
  FollowRepository(this._ref);

  final Ref _ref;

  String? get _userId => _ref.read(supabaseProvider).auth.currentUser?.id;

  Future<bool> isFollowing(String userId) async {
    final me = _userId;
    if (me == null) return false;
    final client = _ref.read(supabaseProvider);
    final row = await client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', me)
        .eq('followed_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> setFollowing(String userId, bool following) async {
    final client = _ref.read(supabaseProvider);
    final me = _userId;
    if (me == null || me == userId) return;
    if (following) {
      await client.from('follows').insert({
        'follower_id': me,
        'followed_id': userId,
      });
    } else {
      await client
          .from('follows')
          .delete()
          .eq('follower_id', me)
          .eq('followed_id', userId);
    }
  }
}

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref);
});

/// Whether the signed-in user follows [userId]. Re-fetch by invalidating
/// this family member after a follow/unfollow.
final isFollowingProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  userId,
) {
  return ref.watch(followRepositoryProvider).isFollowing(userId);
});

/// User ids with a follow toggle currently in flight — same in-flight guard
/// pattern as likeTogglingProvider/repostTogglingProvider.
final followTogglingProvider = StateProvider<Set<String>>((ref) => {});
