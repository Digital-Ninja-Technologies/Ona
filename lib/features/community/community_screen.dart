import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/community_repository.dart';
import '../../core/models/community_post.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../auth/auth_controller.dart';

const _postTypes = [
  ('all', 'All Posts'),
  ('story', 'Stories'),
  ('tip', 'Tips'),
  ('question', 'Questions'),
];

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityPostsProvider);
    final selectedType = ref.watch(postTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () async {
              if (ref.read(currentUserProvider) == null) {
                context.push('/auth/signin');
                return;
              }
              final created = await context.push<bool>('/community/create');
              if (created == true) ref.invalidate(communityPostsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community-ai-assistant',
        onPressed: () => context.push('/ai-assistant'),
        child: const Icon(LucideIcons.sparkles),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _postTypes.map((entry) {
                    final (value, label) = entry;
                    final selected = selectedType == value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) =>
                            ref.read(postTypeFilterProvider.notifier).state =
                                value,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(communityPostsProvider),
                child: postsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorView(
                    message: 'Could not load the community feed.',
                    onRetry: () => ref.invalidate(communityPostsProvider),
                  ),
                  data: (posts) => posts.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No posts yet. Be the first to share!',
                                      style: AppTheme.poppins(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: posts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) =>
                              _PostCard(post: posts[index]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _typeLabels = {'story': 'Story', 'tip': 'Tip', 'question': 'Question'};

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

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
    } catch (_) {
      // The DB is the source of truth either way — a benign race (e.g. a
      // duplicate-key error from an overlapping toggle) just means the
      // refetch below will show whatever the server actually has.
    } finally {
      togglingNotifier.state = {...togglingNotifier.state}..remove(post.id);
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  post.author.displayName[0].toUpperCase(),
                  style: AppTheme.fredoka(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author.displayName,
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
              const SizedBox(width: 20),
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
            ],
          ),
        ],
      ),
    );
  }
}
