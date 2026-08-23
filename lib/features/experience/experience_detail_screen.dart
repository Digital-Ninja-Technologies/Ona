import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/destinations_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class ExperienceDetailScreen extends ConsumerWidget {
  const ExperienceDetailScreen({super.key, required this.experienceId});

  final String experienceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experienceAsync = ref.watch(experienceDetailProvider(experienceId));

    return Scaffold(
      body: experienceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load this experience.',
            style: AppTheme.poppins(color: AppColors.error),
          ),
        ),
        data: (experience) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: Padding(
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    child: IconButton(
                      icon: const Icon(
                        LucideIcons.share2,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sharing ${experience.title}...'),
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: experience.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: experience.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppColors.surface),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.title,
                      style: AppTheme.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (experience.category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        experience.category!,
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        _MetaItem(
                          icon: LucideIcons.star,
                          label: experience.rating?.toStringAsFixed(1) ?? '—',
                        ),
                        if (experience.durationHours != null)
                          _MetaItem(
                            icon: LucideIcons.clock,
                            label: '${experience.durationHours} hrs',
                          ),
                        if (experience.maxParticipants != null)
                          _MetaItem(
                            icon: LucideIcons.users,
                            label: 'Up to ${experience.maxParticipants}',
                          ),
                      ],
                    ),
                    if (experience.description != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'About this experience',
                        style: AppTheme.fredoka(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        experience.description!,
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: experienceAsync.maybeWhen(
        data: (experience) => SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${experience.price.toStringAsFixed(0)}',
                        style: AppTheme.fredoka(fontSize: 20),
                      ),
                      Text(
                        'per person',
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push(
                    '/booking-flow',
                    extra: {'experienceId': experienceId},
                  ),
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.poppins(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
