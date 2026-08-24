import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/itineraries_repository.dart';
import '../../core/models/itinerary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class ItinerariesScreen extends ConsumerWidget {
  const ItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerariesAsync = ref.watch(itinerariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Itineraries'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () async {
              final created = await context.push<bool>('/itinerary-create');
              if (created == true) ref.invalidate(itinerariesProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(itinerariesProvider),
          child: itinerariesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Could not load your itineraries.',
                style: AppTheme.poppins(color: AppColors.error),
              ),
            ),
            data: (itineraries) => itineraries.isEmpty
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
                                  LucideIcons.calendar,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No Itineraries Yet',
                                  style: AppTheme.fredoka(fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start planning your dream trip with AI '
                                  'assistance or build one manually.',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.poppins(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final created = await context.push<bool>(
                                      '/itinerary-create',
                                    );
                                    if (created == true) {
                                      ref.invalidate(itinerariesProvider);
                                    }
                                  },
                                  icon: const Icon(LucideIcons.plus),
                                  label: const Text('Create Itinerary'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: itineraries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        _ItineraryCard(itinerary: itineraries[index]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ItineraryCard extends ConsumerWidget {
  const _ItineraryCard({required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/itinerary/${itinerary.id}'),
      child: Container(
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
                Expanded(
                  child: Text(
                    itinerary.title,
                    style: AppTheme.fredoka(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (itinerary.isAiGenerated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.sparkles,
                          size: 12,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: AppTheme.poppins(
                            fontSize: 11,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${itinerary.durationDays} day${itinerary.durationDays > 1 ? 's' : ''}',
                  style: AppTheme.poppins(color: AppColors.textSecondary),
                ),
                if (itinerary.destinationName != null) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      itinerary.destinationName!,
                      style: AppTheme.poppins(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.share2, size: 18),
                  onPressed: () {
                    final buffer = StringBuffer(
                      'Check out my ${itinerary.title} itinerary!\n',
                    );
                    if (itinerary.description != null) {
                      buffer.writeln(itinerary.description);
                    }
                    buffer.writeln('Duration: ${itinerary.durationDays} days');
                    if (itinerary.destinationName != null) {
                      buffer.writeln(
                        'Destination: ${itinerary.destinationName}',
                      );
                    }
                    if (itinerary.isAiGenerated) {
                      buffer.writeln('\n✨ Created with AI');
                    }
                    SharePlus.instance.share(
                      ShareParams(
                        text: buffer.toString(),
                        subject: itinerary.title,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: AppColors.error,
                  ),
                  onPressed: () async {
                    await ref
                        .read(itinerariesRepositoryProvider)
                        .deleteItinerary(itinerary.id);
                    ref.invalidate(itinerariesProvider);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
