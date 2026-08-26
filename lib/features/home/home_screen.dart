import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/destinations_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/destination_card.dart';
import '../../core/widgets/error_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(popularDestinationsProvider);
    final experiences = ref.watch(popularExperiencesProvider);
    final selectedDestinationId = ref.watch(
      selectedExperienceDestinationProvider,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'home-ai-assistant',
        onPressed: () => context.push('/ai-assistant'),
        child: const Icon(LucideIcons.sparkles),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(popularDestinationsProvider);
            ref.invalidate(popularExperiencesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/brand/ona-logo.png',
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/tabs/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.search,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Search destinations',
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Popular Destinations',
                style: AppTheme.fredoka(fontSize: 18),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
                child: destinations.when(
                  data: (items) => items.isEmpty
                      ? Center(
                          child: Text(
                            'No destinations yet',
                            style: AppTheme.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) => DestinationCard(
                            destination: items[index],
                            onTap: () =>
                                context.push('/destination/${items[index].id}'),
                          ),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorView(
                    message: 'Could not load destinations',
                    onRetry: () => ref.invalidate(popularDestinationsProvider),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Local Experiences', style: AppTheme.fredoka(fontSize: 18)),
              const SizedBox(height: 12),
              destinations.maybeWhen(
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final id = index == 0 ? null : items[index - 1].id;
                            final label = index == 0
                                ? 'All'
                                : items[index - 1].name;
                            final selected = selectedDestinationId == id;
                            return ChoiceChip(
                              label: Text(label),
                              selected: selected,
                              onSelected: (_) => ref
                                  .read(
                                    selectedExperienceDestinationProvider
                                        .notifier,
                                  )
                                  .state = id,
                              labelStyle: AppTheme.poppins(
                                fontSize: 13,
                                color: selected ? Colors.white : AppColors.text,
                              ),
                              backgroundColor: AppColors.surface,
                              selectedColor: AppColors.primary,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            );
                          },
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              experiences.when(
                data: (items) => items.isEmpty
                    ? Text(
                        selectedDestinationId == null
                            ? 'No experiences yet'
                            : 'No experiences here yet',
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      )
                    : Column(
                        children: items
                            .map(
                              (experience) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => context.push(
                                    '/experience/${experience.id}',
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                experience.title,
                                                style: AppTheme.fredoka(
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '\$${experience.price.toStringAsFixed(0)}',
                                                style: AppTheme.poppins(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
                  message: 'Could not load experiences',
                  onRetry: () => ref.invalidate(popularExperiencesProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
