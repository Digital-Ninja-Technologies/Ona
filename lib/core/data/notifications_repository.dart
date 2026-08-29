import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/app_notification.dart';
import 'public_profiles_repository.dart';

class NotificationsRepository {
  NotificationsRepository(this._ref);

  final Ref _ref;

  String? get _userId => _ref.read(supabaseProvider).auth.currentUser?.id;

  Future<List<AppNotification>> fetchNotifications({int limit = 50}) async {
    final client = _ref.read(supabaseProvider);
    final userId = _userId;
    if (userId == null) return [];
    final rows = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    final notificationRows = List<Map<String, dynamic>>.from(rows as List);
    if (notificationRows.isEmpty) return [];

    final actorIds = notificationRows.map((row) => row['actor_id'] as String);
    final profiles = await fetchPublicProfiles(client, actorIds);

    return notificationRows
        .map(
          (row) => AppNotification.fromJson(
            row,
            actor: profileOrFallback(profiles, row['actor_id'] as String),
          ),
        )
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final client = _ref.read(supabaseProvider);
    final userId = _userId;
    if (userId == null) return 0;
    final rows = await client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('read', false);
    return (rows as List).length;
  }

  Future<void> markAllRead() async {
    final client = _ref.read(supabaseProvider);
    final userId = _userId;
    if (userId == null) return;
    await client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref);
});

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((
  ref,
) {
  return ref.watch(notificationsRepositoryProvider).fetchNotifications();
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) {
  return ref.watch(notificationsRepositoryProvider).fetchUnreadCount();
});
