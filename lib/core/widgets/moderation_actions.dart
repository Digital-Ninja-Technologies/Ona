import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/follow_repository.dart';
import '../data/messages_repository.dart';
import '../data/moderation_repository.dart';
import '../data/public_profiles_repository.dart';

/// Shared Twitter-style moderation actions — block/unblock, report, and
/// delete-conversation — used from the user profile screen, the messages
/// list, and the chat screen so the confirmation copy and provider
/// invalidation stay consistent everywhere they appear.
Future<void> confirmAndToggleBlock(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String displayName,
  required bool currentlyBlocked,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(currentlyBlocked ? 'Unblock $displayName?' : 'Block $displayName?'),
      content: Text(
        currentlyBlocked
            ? '$displayName will be able to follow and message you again.'
            : '$displayName won\'t be able to follow or message you, and '
                  'you\'ll unfollow each other.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(currentlyBlocked ? 'Unblock' : 'Block'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await ref
        .read(moderationRepositoryProvider)
        .setBlocking(userId, !currentlyBlocked);
    ref.invalidate(isBlockingProvider(userId));
    ref.invalidate(isFollowingProvider(userId));
    ref.invalidate(userProfileProvider(userId));
    ref.invalidate(conversationsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyBlocked ? 'Unblocked.' : 'Blocked.'),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyBlocked ? 'Could not unblock.' : 'Could not block.',
          ),
        ),
      );
    }
  }
}

Future<void> confirmAndReportUser(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String displayName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Report $displayName?'),
      content: const Text(
        'This sends a report to the Ọ̀nà team for review. It won\'t '
        'notify this user.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Report'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await ref.read(moderationRepositoryProvider).reportUser(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your report was sent.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send your report.')),
      );
    }
  }
}

/// Returns true if the conversation was deleted (so callers viewing a
/// single conversation, like [ChatScreen], know to navigate away).
Future<bool> confirmAndDeleteConversation(
  BuildContext context,
  WidgetRef ref, {
  required String conversationId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete conversation?'),
      content: const Text(
        'This removes it from your inbox. It\'ll come back if they send '
        'you another message.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    await ref.read(messagesRepositoryProvider).deleteConversation(
      conversationId,
    );
    ref.invalidate(conversationsProvider);
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete conversation.')),
      );
    }
    return false;
  }
}

/// The block/report/delete-conversation bottom sheet shared by the
/// messages list (long-press a conversation) and the chat screen's
/// overflow menu.
Future<void> showConversationActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String conversationId,
  required String otherUserId,
  required String otherUserDisplayName,
  required bool isBlocked,
  VoidCallback? onConversationDeleted,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete conversation'),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
          ListTile(
            leading: Icon(isBlocked ? Icons.lock_open : Icons.block),
            title: Text(isBlocked ? 'Unblock' : 'Block'),
            onTap: () => Navigator.of(context).pop('block'),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report'),
            onTap: () => Navigator.of(context).pop('report'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case 'delete':
      final deleted = await confirmAndDeleteConversation(
        context,
        ref,
        conversationId: conversationId,
      );
      if (deleted) onConversationDeleted?.call();
    case 'block':
      await confirmAndToggleBlock(
        context,
        ref,
        userId: otherUserId,
        displayName: otherUserDisplayName,
        currentlyBlocked: isBlocked,
      );
    case 'report':
      await confirmAndReportUser(
        context,
        ref,
        userId: otherUserId,
        displayName: otherUserDisplayName,
      );
  }
}
