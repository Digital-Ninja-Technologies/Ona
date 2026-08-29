import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/community_repository.dart';
import '../../core/models/post_comment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import 'widgets/post_card.dart';

class PostCommentsScreen extends ConsumerStatefulWidget {
  const PostCommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  bool _sending = false;

  // Non-null while composing a reply — _replyRootId is always a top-level
  // comment's id (replying to a reply still targets that reply's own root,
  // so every reply thread stays one level deep; see PostComment.isReply).
  // _replyToName is who was actually tapped, purely for the "Replying to…"
  // banner — it may be a reply's author, not the root comment's.
  String? _replyRootId;
  String? _replyToName;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _startReply(PostComment comment) {
    setState(() {
      _replyRootId = comment.parentCommentId ?? comment.id;
      _replyToName = comment.author.handle;
    });
    _inputFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyRootId = null;
      _replyToName = null;
    });
  }

  Future<void> _send() async {
    if (ref.read(currentUserProvider) == null) {
      context.push('/auth/signin');
      return;
    }
    final content = _inputController.text.trim();
    if (content.isEmpty || _sending) return;
    final parentCommentId = _replyRootId;
    setState(() => _sending = true);
    _inputController.clear();
    try {
      await ref
          .read(communityRepositoryProvider)
          .addComment(
            postId: widget.postId,
            content: content,
            parentCommentId: parentCommentId,
          );
      ref.invalidate(postCommentsProvider(widget.postId));
      ref.invalidate(communityPostsProvider);
      if (mounted) _cancelReply();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post your comment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(singlePostProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  postAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => const SizedBox.shrink(),
                    data: (post) => post == null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'This post is no longer available.',
                              style: AppTheme.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PostCard(post: post),
                          ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  commentsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => ErrorView(
                      message: 'Could not load comments.',
                      onRetry: () =>
                          ref.invalidate(postCommentsProvider(widget.postId)),
                    ),
                    data: (comments) => comments.isEmpty
                        ? Text(
                            'No comments yet. Start the conversation!',
                            style: AppTheme.poppins(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : _CommentThreadList(
                            comments: comments,
                            onReply: _startReply,
                          ),
                  ),
                ],
              ),
            ),
            if (_replyToName != null)
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
                        'Replying to $_replyToName',
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelReply,
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
                        hintText: _replyToName == null
                            ? 'Add a comment...'
                            : 'Reply to $_replyToName...',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(LucideIcons.send),
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

/// Groups a flat comment list into top-level comments with their replies
/// nested directly beneath — see PostComment.parentCommentId.
class _CommentThreadList extends StatelessWidget {
  const _CommentThreadList({required this.comments, required this.onReply});

  final List<PostComment> comments;
  final ValueChanged<PostComment> onReply;

  @override
  Widget build(BuildContext context) {
    final roots = comments.where((c) => !c.isReply).toList();
    final repliesByRoot = <String, List<PostComment>>{};
    for (final comment in comments) {
      final rootId = comment.parentCommentId;
      if (rootId != null) {
        repliesByRoot.putIfAbsent(rootId, () => []).add(comment);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < roots.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _CommentTile(comment: roots[i], onReply: () => onReply(roots[i])),
          for (final reply in repliesByRoot[roots[i].id] ?? const [])
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 42),
              child: _CommentTile(
                comment: reply,
                onReply: () => onReply(reply),
              ),
            ),
        ],
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onReply});

  final PostComment comment;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          name: comment.author.displayName,
          imageUrl: comment.author.profileImage,
          radius: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.author.handle,
                    style: AppTheme.fredoka(fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd().format(comment.createdAt),
                    style: AppTheme.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.content, style: AppTheme.poppins(fontSize: 14)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onReply,
                child: Text(
                  'Reply',
                  style: AppTheme.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
