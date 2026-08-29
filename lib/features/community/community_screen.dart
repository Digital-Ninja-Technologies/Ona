import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/community_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../auth/auth_controller.dart';
import 'widgets/post_card.dart';

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
                              PostCard(post: posts[index]),
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
