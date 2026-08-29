import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/itineraries_repository.dart';
import '../../core/models/itinerary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import 'widgets/activity_link.dart';

Itinerary? _findById(List<Itinerary> itineraries, String id) {
  for (final itinerary in itineraries) {
    if (itinerary.id == id) return itinerary;
  }
  return null;
}

class ItineraryDetailScreen extends ConsumerWidget {
  const ItineraryDetailScreen({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerariesAsync = ref.watch(itinerariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary'),
        actions: [
          itinerariesAsync.maybeWhen(
            data: (itineraries) {
              final itinerary = _findById(itineraries, itineraryId);
              if (itinerary == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(LucideIcons.share2),
                onPressed: () {
                  final buffer = StringBuffer(
                    'Check out my ${itinerary.title} itinerary!\n',
                  );
                  if (itinerary.description != null) {
                    buffer.writeln(itinerary.description);
                  }
                  SharePlus.instance.share(
                    ShareParams(
                      text: buffer.toString(),
                      subject: itinerary.title,
                    ),
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: itinerariesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message: 'Could not load this itinerary.',
            onRetry: () => ref.invalidate(itinerariesProvider),
          ),
          data: (itineraries) {
            final itinerary = _findById(itineraries, itineraryId);
            if (itinerary == null) {
              return Center(
                child: Text(
                  'Itinerary not found.',
                  style: AppTheme.poppins(color: AppColors.textSecondary),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(itinerary.title, style: AppTheme.fredoka(fontSize: 22)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 16,
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
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        itinerary.destinationName!,
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                if (itinerary.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    itinerary.description!,
                    style: AppTheme.poppins(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 24),
                for (final day in itinerary.days)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${day.day}',
                          style: AppTheme.fredoka(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        for (final activity in day.activities)
                          ActivityLink(
                            activity: activity,
                            destinationName: itinerary.destinationName,
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
