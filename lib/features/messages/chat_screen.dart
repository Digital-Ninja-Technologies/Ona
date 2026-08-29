import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/messages_repository.dart';
import '../../core/data/moderation_repository.dart';
import '../../core/models/chat_message.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/moderation_actions.dart';
import '../auth/auth_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _sending = false;
  int _lastMessageCount = 0;

  // Non-null while composing a reply — cleared on send/cancel. Mutually
  // exclusive with _editingMessage.
  ChatMessage? _replyingTo;

  // Non-null while editing a previously-sent message — the input is
  // prefilled with its content and _send() updates it in place instead of
  // posting a new message.
  ChatMessage? _editingMessage;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.invalidate(chatMessagesProvider(widget.conversationId));
    });
    // Mark read on open — fire-and-forget, a failure here shouldn't block
    // viewing the conversation.
    ref
        .read(messagesRepositoryProvider)
        .markConversationRead(widget.conversationId)
        .then((_) => ref.invalidate(conversationsProvider))
        .catchError((_) {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _startReply(ChatMessage message) {
    setState(() {
      _editingMessage = null;
      _replyingTo = message;
    });
    _inputFocusNode.requestFocus();
  }

  void _startEdit(ChatMessage message) {
    setState(() {
      _replyingTo = null;
      _editingMessage = message;
      _inputController.text = message.content;
    });
    _inputFocusNode.requestFocus();
  }

  void _cancelComposeContext() {
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _inputController.clear();
    });
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: AppTheme.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(messagesRepositoryProvider).deleteMessage(message.id);
      ref.invalidate(chatMessagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not delete message.')));
      }
    }
  }

  Future<void> _showMessageActions(ChatMessage message, bool isMe) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.copy),
              title: const Text('Copy'),
              onTap: () => Navigator.of(context).pop('copy'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.reply),
              title: const Text('Reply'),
              onTap: () => Navigator.of(context).pop('reply'),
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(LucideIcons.pencil),
                title: const Text('Edit'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              ListTile(
                leading: Icon(LucideIcons.trash2, color: AppColors.error),
                title: Text(
                  'Delete',
                  style: AppTheme.poppins(color: AppColors.error),
                ),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.content));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied.')));
        }
      case 'reply':
        _startReply(message);
      case 'edit':
        _startEdit(message);
      case 'delete':
        await _deleteMessage(message);
    }
  }

  Future<void> _send() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _sending) return;

    if (_editingMessage != null) {
      final editing = _editingMessage!;
      setState(() => _sending = true);
      try {
        await ref
            .read(messagesRepositoryProvider)
            .editMessage(editing.id, content);
        ref.invalidate(chatMessagesProvider(widget.conversationId));
        if (mounted) _cancelComposeContext();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not save edit.')));
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }

    final replyToId = _replyingTo?.id;
    setState(() => _sending = true);
    _inputController.clear();
    try {
      await ref
          .read(messagesRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            content: content,
            replyToId: replyToId,
          );
      ref.invalidate(chatMessagesProvider(widget.conversationId));
      if (mounted) setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (_) {
      _inputController.text = content;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send message.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final otherUserAsync = ref.watch(
      chatOtherUserProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversationId),
    );

    final otherUserId = otherUserAsync.valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (otherUserId != null) context.push('/user/$otherUserId');
          },
          child: Text(
            otherUserAsync.valueOrNull?.displayName ?? 'Chat',
            style: AppTheme.fredoka(fontSize: 18),
          ),
        ),
        actions: [
          if (otherUserId != null)
            IconButton(
              icon: const Icon(LucideIcons.moreVertical),
              onPressed: () async {
                final isBlocked = await ref.read(
                  isBlockingProvider(otherUserId).future,
                );
                if (!context.mounted) return;
                await showConversationActionsSheet(
                  context,
                  ref,
                  conversationId: widget.conversationId,
                  otherUserId: otherUserId,
                  otherUserDisplayName:
                      otherUserAsync.valueOrNull?.displayName ?? 'this user',
                  isBlocked: isBlocked,
                  onConversationDeleted: () {
                    if (context.mounted) context.pop();
                  },
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: 'Could not load messages.',
                  onRetry: () =>
                      ref.invalidate(chatMessagesProvider(widget.conversationId)),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Say hello!',
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  if (messages.length != _lastMessageCount) {
                    _lastMessageCount = messages.length;
                    _scrollToBottom();
                  }
                  final byId = {
                    for (final message in messages) message.id: message,
                  };
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == me?.id;
                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                        repliedTo: message.replyToId != null
                            ? byId[message.replyToId]
                            : null,
                        onLongPress: () => _showMessageActions(message, isMe),
                      );
                    },
                  );
                },
              ),
            ),
            if (_replyingTo != null || _editingMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppColors.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _editingMessage != null
                            ? 'Editing message'
                            : 'Replying to "${_replyingTo!.content}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelComposeContext,
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                      decoration: InputDecoration(
                        hintText: _editingMessage != null
                            ? 'Edit message...'
                            : 'Type a message...',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: Icon(
                      _editingMessage != null
                          ? LucideIcons.check
                          : LucideIcons.send,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.repliedTo,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool isMe;

  /// The message being replied to, if [message] is a reply and the
  /// original is still loaded in this conversation.
  final ChatMessage? repliedTo;

  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (repliedTo != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.white : AppColors.background)
                        .withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    repliedTo!.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.poppins(
                      fontSize: 12,
                      color: isMe ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                message.content,
                style: AppTheme.poppins(
                  color: isMe ? Colors.white : AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message.isEdited
                    ? '${DateFormat.Hm().format(message.createdAt)} · edited'
                    : DateFormat.Hm().format(message.createdAt),
                style: AppTheme.poppins(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
