import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/messages_repository.dart';
import '../../core/models/conversation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
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
                                  'No messages yet',
                                  style: AppTheme.fredoka(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Start a conversation with a travel agent to see it here.',
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

class _ConversationTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary,
        child: Text(
          conversation.otherUser.displayName[0].toUpperCase(),
          style: AppTheme.fredoka(color: Colors.white, fontSize: 18),
        ),
      ),
      title: Text(
        conversation.otherUser.displayName,
        style: AppTheme.fredoka(fontSize: 15),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'Say hello!',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.poppins(color: AppColors.textSecondary),
      ),
      trailing: Text(
        _formatTime(conversation.lastMessageAt),
        style: AppTheme.poppins(fontSize: 11, color: AppColors.textSecondary),
      ),
      onTap: () => context.push('/chat/${conversation.id}'),
    );
  }
}
