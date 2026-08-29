import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/community_repository.dart';
import '../../../core/models/community_post.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/auth_controller.dart';

const _typeLabels = {'story': 'Story', 'tip': 'Tip', 'question': 'Question'};

enum _RepostAction { toggleRepost, quote }

/// One community post — author (tappable through to their profile), the
/// post body/photo, and the like/comment/repost/share action row. Shared by
/// the community feed and a user's profile screen so both stay in sync.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final CommunityPost post;

  Future<void> _toggleLike(WidgetRef ref, BuildContext context) async {
    if (ref.read(currentUserProvider) == null) {
      context.push('/auth/signin');
      return;
    }
    final togglingNotifier = ref.read(likeTogglingProvider.notifier);
    if (togglingNotifier.state.contains(post.id)) return;
    togglingNotifier.state = {...togglingNotifier.state, post.id};
    try {
      final nextLiked = !post.isLikedByMe;
      await ref.read(communityRepositoryProvider).setLiked(post.id, nextLiked);
      ref.invalidate(communityPostsProvider);
      ref.invalidate(userPostsProvider(post.author.id));
    } catch (_) {
      // The DB is the source of truth either way — a benign race (e.g. a
      // duplicate-key error from an overlapping toggle) just means the
      // refetch below will show whatever the server actually has.
    } finally {
      togglingNotifier.state = {...togglingNotifier.state}..remove(post.id);
    }
  }

  Future<void> _toggleRepost(WidgetRef ref, BuildContext context) async {
    if (ref.read(currentUserProvider) == null) {
      context.push('/auth/signin');
      return;
    }
    final togglingNotifier = ref.read(repostTogglingProvider.notifier);
    if (togglingNotifier.state.contains(post.id)) return;
    togglingNotifier.state = {...togglingNotifier.state, post.id};
    try {
      final nextReposted = !post.isRepostedByMe;
      await ref
          .read(communityRepositoryProvider)
          .setReposted(post.id, nextReposted);
      ref.invalidate(communityPostsProvider);
      ref.invalidate(userPostsProvider(post.author.id));
    } catch (_) {
      // Same benign-race reasoning as _toggleLike.
    } finally {
      togglingNotifier.state = {...togglingNotifier.state}..remove(post.id);
    }
  }

  Future<void> _openRepostMenu(WidgetRef ref, BuildContext context) async {
    if (ref.read(currentUserProvider) == null) {
      context.push('/auth/signin');
      return;
    }
    final action = await showModalBottomSheet<_RepostAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                LucideIcons.repeat2,
                color: post.isRepostedByMe ? AppColors.verified : null,
              ),
              title: Text(
                post.isRepostedByMe ? 'Undo repost' : 'Repost',
              ),
              onTap: () =>
                  Navigator.of(context).pop(_RepostAction.toggleRepost),
            ),
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: const Text('Quote'),
              onTap: () => Navigator.of(context).pop(_RepostAction.quote),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _RepostAction.toggleRepost:
        await _toggleRepost(ref, context);
      case _RepostAction.quote:
        final posted = await context.push<bool>(
          '/community/create',
          extra: post,
        );
        if (posted == true) {
          ref.invalidate(communityPostsProvider);
          ref.invalidate(userPostsProvider(post.author.id));
        }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppTheme.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communityRepositoryProvider).deletePost(post.id);
      ref.invalidate(communityPostsProvider);
      ref.invalidate(userPostsProvider(post.author.id));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete your post.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/user/${post.author.id}'),
                child: UserAvatar(
                  name: post.author.displayName,
                  imageUrl: post.author.profileImage,
                  radius: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/user/${post.author.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.handle,
                        style: AppTheme.fredoka(fontSize: 15),
                      ),
                      Text(
                        DateFormat.yMMMd().format(post.createdAt),
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _typeLabels[post.type] ?? post.type,
                  style: AppTheme.poppins(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (post.author.id == ref.watch(currentUserProvider)?.id)
                PopupMenuButton<String>(
                  icon: const Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') _confirmDelete(context, ref);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete post',
                        style: AppTheme.poppins(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content, style: AppTheme.poppins()),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (post.quotedPost != null) ...[
            const SizedBox(height: 12),
            _QuotedPostEmbed(post: post.quotedPost!),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: ref.watch(likeTogglingProvider).contains(post.id)
                    ? null
                    : () => _toggleLike(ref, context),
                child: Row(
                  children: [
                    Icon(
                      post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: post.isLikedByMe
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likesCount}',
                      style: AppTheme.poppins(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => context.push('/community/${post.id}/comments'),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.messageCircle,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentsCount}',
                      style: AppTheme.poppins(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: ref.watch(repostTogglingProvider).contains(post.id)
                    ? null
                    : () => _openRepostMenu(ref, context),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.repeat2,
                      size: 20,
                      color: post.isRepostedByMe
                          ? AppColors.verified
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.repostsCount}',
                      style: AppTheme.poppins(
                        color: post.isRepostedByMe
                            ? AppColors.verified
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${post.author.handle} on Ọ̀nà:\n\n'
                        '${post.content}',
                    subject: 'A post from Ọ̀nà',
                  ),
                ),
                child: const Icon(
                  LucideIcons.share2,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The original post embedded inside a quote-repost — tapping it opens that
/// user's profile, same as tapping an author elsewhere in the app.
class _QuotedPostEmbed extends StatelessWidget {
  const _QuotedPostEmbed({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/user/${post.author.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: post.author.displayName,
                  imageUrl: post.author.profileImage,
                  radius: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  post.author.handle,
                  style: AppTheme.fredoka(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.poppins(fontSize: 13),
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
