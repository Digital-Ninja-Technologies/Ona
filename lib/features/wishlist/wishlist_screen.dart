import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/bookings_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/destination_card.dart';
import '../../core/widgets/error_view.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedDestinationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(savedDestinationsProvider),
          child: savedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              message: 'Could not load your wishlist.',
              onRetry: () => ref.invalidate(savedDestinationsProvider),
            ),
            data: (destinations) => destinations.isEmpty
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
                                  LucideIcons.heart,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No saved destinations yet',
                                  style: AppTheme.fredoka(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap the heart on a destination to save it here.',
                                  style: AppTheme.poppins(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: destinations.length,
                    separatorBuilder: (_, _) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final destination = destinations[index];
                      return Row(
                        children: [
                          Expanded(
                            child: DestinationCard(
                              destination: destination,
                              width: double.infinity,
                              onTap: () => context.push(
                                '/destination/${destination.id}',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              color: AppColors.error,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(bookingsRepositoryProvider)
                                  .removeSavedDestination(destination.id);
                              ref.invalidate(savedDestinationsProvider);
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
