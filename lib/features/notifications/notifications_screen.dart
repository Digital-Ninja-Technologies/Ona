import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/notifications_repository.dart';
import '../../core/models/app_notification.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/user_avatar.dart';

const _typeIcons = {
  NotificationType.follow: LucideIcons.userPlus,
  NotificationType.like: Icons.favorite,
  NotificationType.comment: LucideIcons.messageCircle,
  NotificationType.repost: LucideIcons.repeat2,
  NotificationType.quote: LucideIcons.pencil,
};

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markedRead = false;

  /// Marks everything read once the list has actually loaded — viewing the
  /// screen is what clears the bell badge, same as most apps.
  void _markAllReadOnce() {
    if (_markedRead) return;
    _markedRead = true;
    ref.read(notificationsRepositoryProvider).markAllRead().then((_) {
      ref.invalidate(unreadNotificationsCountProvider);
    });
  }

  void _open(AppNotification notification) {
    if (notification.type == NotificationType.follow) {
      context.push('/user/${notification.actor.id}');
    } else if (notification.postId != null) {
      context.push('/community/${notification.postId}/comments');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(notificationsProvider),
          child: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              message: 'Could not load notifications.',
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Text(
                          "No notifications yet — you'll see follows, "
                          'likes, comments, and reposts here.',
                          textAlign: TextAlign.center,
                          style: AppTheme.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _markAllReadOnce(),
              );
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    onTap: () => _open(notification),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
      leading: Stack(
        children: [
          UserAvatar(
            name: notification.actor.displayName,
            imageUrl: notification.actor.profileImage,
            radius: 22,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _typeIcons[notification.type],
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      title: Text(notification.message, style: AppTheme.poppins(fontSize: 14)),
      subtitle: Text(
        DateFormat.yMMMd().add_jm().format(notification.createdAt),
        style: AppTheme.poppins(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: notification.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}
