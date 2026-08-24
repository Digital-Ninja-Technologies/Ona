import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/bookings_repository.dart';
import '../../core/data/destinations_repository.dart';
import '../../core/data/reviews_repository.dart';
import '../../core/models/attraction.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class DestinationDetailScreen extends ConsumerWidget {
  const DestinationDetailScreen({super.key, required this.destinationId});

  final String destinationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationAsync = ref.watch(
      destinationDetailProvider(destinationId),
    );
    final attractionsAsync = ref.watch(attractionsProvider(destinationId));
    final savedAsync = ref.watch(isDestinationSavedProvider(destinationId));

    return Scaffold(
      body: destinationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load this destination.',
            style: AppTheme.poppins(color: AppColors.error),
          ),
        ),
        data: (destination) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: _CircleButton(
                icon: LucideIcons.arrowLeft,
                onTap: () => context.pop(),
              ),
              actions: [
                _CircleButton(
                  icon: LucideIcons.heart,
                  isActive: savedAsync.valueOrNull == true,
                  onTap: () async {
                    final togglingNotifier = ref.read(
                      saveTogglingProvider.notifier,
                    );
                    if (togglingNotifier.state.contains(destinationId)) return;
                    togglingNotifier.state = {
                      ...togglingNotifier.state,
                      destinationId,
                    };
                    try {
                      await ref
                          .read(bookingsRepositoryProvider)
                          .toggleSaved(destinationId);
                      ref.invalidate(isDestinationSavedProvider(destinationId));
                    } catch (_) {
                      // Benign race with another in-flight toggle — the
                      // refetch above (if it ran) reflects the real state.
                    } finally {
                      togglingNotifier.state = {...togglingNotifier.state}
                        ..remove(destinationId);
                    }
                  },
                ),
                _CircleButton(
                  icon: LucideIcons.share2,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing ${destination.name}...')),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: destination.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: destination.imageUrl!,
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
                      destination.name,
                      style: AppTheme.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          destination.country,
                          style: AppTheme.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.star,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          destination.rating?.toStringAsFixed(1) ?? '4.5',
                          style: AppTheme.poppins(fontWeight: FontWeight.w600),
                        ),
                        if (destination.priceRange != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            destination.priceRange!,
                            style: AppTheme.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (destination.description != null) ...[
                      const SizedBox(height: 20),
                      _SectionTitle('About'),
                      const SizedBox(height: 8),
                      Text(
                        destination.description!,
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    ],
                    if (destination.bestTimeToVisit != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Best Time to Visit',
                                    style: AppTheme.fredoka(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    destination.bestTimeToVisit!,
                                    style: AppTheme.poppins(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (destination.popularActivities.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionTitle('Popular Activities'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: destination.popularActivities
                            .map(
                              (activity) => Chip(
                                label: Text(
                                  activity,
                                  style: AppTheme.poppins(fontSize: 13),
                                ),
                                backgroundColor: AppColors.surface,
                                side: BorderSide.none,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SectionTitle('Reviews'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.push(
                        '/reviews',
                        extra: {
                          'target': ReviewTarget.destination(destinationId),
                          'title': destination.name,
                        },
                      ),
                      child: const Text('Write a Review'),
                    ),
                    const SizedBox(height: 20),
                    attractionsAsync.when(
                      data: (attractions) => attractions.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle('Top Attractions'),
                                const SizedBox(height: 10),
                                ...attractions.map(
                                  (attraction) =>
                                      _AttractionCard(attraction: attraction),
                                ),
                              ],
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: destinationAsync.maybeWhen(
        data: (destination) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                context.go('/tabs/itineraries');
              },
              child: const Text('Plan a Trip'),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTheme.fredoka(fontSize: 18));
  }
}

class _AttractionCard extends StatelessWidget {
  const _AttractionCard({required this.attraction});

  final Attraction attraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 84,
              height: 84,
              child: attraction.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: attraction.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: AppColors.surface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attraction.name, style: AppTheme.fredoka(fontSize: 15)),
                if (attraction.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    attraction.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (attraction.rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.star,
                        size: 12,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        attraction.rating!.toStringAsFixed(1),
                        style: AppTheme.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        child: IconButton(
          icon: Icon(
            icon,
            color: isActive ? AppColors.primary : Colors.white,
            size: 20,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }
}
