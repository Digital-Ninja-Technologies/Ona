import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';

/// Blocking and reporting other users — the Twitter-style moderation tools
/// alongside follow/messaging. Blocking someone also drops any follow
/// relationship between the two accounts (enforced by a DB trigger).
class ModerationRepository {
  ModerationRepository(this._ref);

  final Ref _ref;

  String? get _userId => _ref.read(supabaseProvider).auth.currentUser?.id;

  Future<bool> isBlocking(String userId) async {
    final me = _userId;
    if (me == null) return false;
    final client = _ref.read(supabaseProvider);
    final row = await client
        .from('blocks')
        .select('blocker_id')
        .eq('blocker_id', me)
        .eq('blocked_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> setBlocking(String userId, bool blocking) async {
    final client = _ref.read(supabaseProvider);
    final me = _userId;
    if (me == null || me == userId) return;
    if (blocking) {
      await client.from('blocks').insert({
        'blocker_id': me,
        'blocked_id': userId,
      });
    } else {
      await client
          .from('blocks')
          .delete()
          .eq('blocker_id', me)
          .eq('blocked_id', userId);
    }
  }

  Future<void> reportUser(String userId, {String? reason}) async {
    final client = _ref.read(supabaseProvider);
    await client.from('user_reports').insert({
      'reporter_id': _userId,
      'reported_id': userId,
      'reason': reason,
    });
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(ref);
});

/// Whether the signed-in user has blocked [userId]. Re-fetch by invalidating
/// this family member after a block/unblock.
final isBlockingProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  userId,
) {
  return ref.watch(moderationRepositoryProvider).isBlocking(userId);
});
