import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/community_repository.dart';
import '../../core/data/follow_repository.dart';
import '../../core/data/messages_repository.dart';
import '../../core/data/public_profiles_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/count_stat.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import '../community/widgets/post_card.dart';

/// Another user's public profile — their photo/name, follower/following
/// counts, a Follow/Unfollow button, and their posts. Reached by tapping an
/// author anywhere in the community feed.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  Future<void> _toggleFollow(
    WidgetRef ref,
    BuildContext context,
    bool currentlyFollowing,
  ) async {
    if (ref.read(currentUserProvider) == null) {
      context.push('/auth/signin');
      return;
    }
    final togglingNotifier = ref.read(followTogglingProvider.notifier);
    if (togglingNotifier.state.contains(userId)) return;
    togglingNotifier.state = {...togglingNotifier.state, userId};
    try {
      await ref
          .read(followRepositoryProvider)
          .setFollowing(userId, !currentlyFollowing);
      ref.invalidate(isFollowingProvider(userId));
      ref.invalidate(isMutualFollowProvider(userId));
      ref.invalidate(userProfileProvider(userId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyFollowing
                  ? 'Could not unfollow.'
                  : 'Could not follow.',
            ),
          ),
        );
      }
    } finally {
      togglingNotifier.state = {...togglingNotifier.state}..remove(userId);
    }
  }

  Future<void> _startMessage(WidgetRef ref, BuildContext context) async {
    try {
      final conversationId = await ref
          .read(messagesRepositoryProvider)
          .getOrCreateConversation(userId);
      if (context.mounted) context.push('/chat/$conversationId');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start a conversation.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final postsAsync = ref.watch(userPostsProvider(userId));
    final isMe = ref.watch(currentUserProvider)?.id == userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message: 'Could not load this profile.',
            onRetry: () => ref.invalidate(userProfileProvider(userId)),
          ),
          data: (profile) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider(userId));
              ref.invalidate(userPostsProvider(userId));
              ref.invalidate(isFollowingProvider(userId));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                UserAvatar(
                  name: profile.displayName,
                  imageUrl: profile.profileImage,
                  radius: 36,
                ),
                const SizedBox(height: 12),
                Text(profile.displayName, style: AppTheme.fredoka(fontSize: 20)),
                if (profile.username != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.handle,
                    style: AppTheme.poppins(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    CountStat(
                      count: profile.followersCount,
                      label: 'Followers',
                    ),
                    const SizedBox(width: 24),
                    CountStat(
                      count: profile.followingCount,
                      label: 'Following',
                    ),
                  ],
                ),
                if (!isMe) ...[
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final followingAsync = ref.watch(
                        isFollowingProvider(userId),
                      );
                      final toggling = ref
                          .watch(followTogglingProvider)
                          .contains(userId);
                      final isFollowing = followingAsync.valueOrNull ?? false;
                      return SizedBox(
                        width: double.infinity,
                        child: isFollowing
                            ? OutlinedButton(
                                onPressed: toggling
                                    ? null
                                    : () => _toggleFollow(
                                        ref,
                                        context,
                                        true,
                                      ),
                                child: toggling
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Following'),
                              )
                            : ElevatedButton(
                                onPressed: toggling
                                    ? null
                                    : () => _toggleFollow(
                                        ref,
                                        context,
                                        false,
                                      ),
                                child: toggling
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Follow'),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final canMessage =
                          ref.watch(isMutualFollowProvider(userId)).valueOrNull ??
                          false;
                      if (!canMessage) {
                        return Text(
                          'Follow each other to start messaging.',
                          textAlign: TextAlign.center,
                          style: AppTheme.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _startMessage(ref, context),
                          icon: const Icon(LucideIcons.messageCircle),
                          label: const Text('Message'),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text('Posts', style: AppTheme.fredoka(fontSize: 16)),
                const SizedBox(height: 12),
                postsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => ErrorView(
                    message: 'Could not load posts.',
                    onRetry: () => ref.invalidate(userPostsProvider(userId)),
                  ),
                  data: (posts) => posts.isEmpty
                      ? Text(
                          'No posts yet.',
                          style: AppTheme.poppins(
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Column(
                          children: posts
                              .map(
                                (post) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: PostCard(post: post),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
