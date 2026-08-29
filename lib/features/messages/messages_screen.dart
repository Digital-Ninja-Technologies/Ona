import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/messages_repository.dart';
import '../../core/data/moderation_repository.dart';
import '../../core/models/conversation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/moderation_actions.dart';
import '../../core/widgets/user_avatar.dart';

const _filterLabels = {
  MessageFilter.all: 'All',
  MessageFilter.read: 'Read',
  MessageFilter.unread: 'Unread',
  MessageFilter.requests: 'Requests',
};

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(filteredConversationsProvider);
    final filter = ref.watch(messageFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: PopupMenuButton<MessageFilter>(
          initialValue: filter,
          onSelected: (value) =>
              ref.read(messageFilterProvider.notifier).state = value,
          itemBuilder: (context) => MessageFilter.values
              .map(
                (value) => PopupMenuItem(
                  value: value,
                  child: Text(_filterLabels[value]!),
                ),
              )
              .toList(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Messages', style: AppTheme.fredoka(fontSize: 18)),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown, size: 18),
              const SizedBox(width: 4),
              Text(
                '· ${_filterLabels[filter]}',
                style: AppTheme.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(conversationsProvider),
          child: conversationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              message: 'Could not load your messages.',
              onRetry: () => ref.invalidate(conversationsProvider),
            ),
            data: (conversations) => conversations.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.messageCircle,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  filter == MessageFilter.all
                                      ? 'No messages yet'
                                      : 'Nothing here',
                                  style: AppTheme.fredoka(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  filter == MessageFilter.requests
                                      ? 'Messages from people you don\'t '
                                            'follow back show up here.'
                                      : 'Start a conversation to see it here.',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.poppins(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 84),
                    itemBuilder: (context, index) =>
                        _ConversationTile(conversation: conversations[index]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}/${time.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = conversation.isUnread;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: UserAvatar(
        name: conversation.otherUser.displayName,
        imageUrl: conversation.otherUser.profileImage,
        radius: 26,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherUser.displayName,
              style: AppTheme.fredoka(fontSize: 15),
            ),
          ),
          if (conversation.isRequest)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Request',
                style: AppTheme.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'Say hello!',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.poppins(
          color: unread ? AppColors.text : AppColors.textSecondary,
          fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageAt),
            style: AppTheme.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (unread) ...[
            const SizedBox(height: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.push('/chat/${conversation.id}'),
      onLongPress: () async {
        final isBlocked = await ref.read(
          isBlockingProvider(conversation.otherUser.id).future,
        );
        if (!context.mounted) return;
        await showConversationActionsSheet(
          context,
          ref,
          conversationId: conversation.id,
          otherUserId: conversation.otherUser.id,
          otherUserDisplayName: conversation.otherUser.displayName,
          isBlocked: isBlocked,
        );
      },
    );
  }
}
