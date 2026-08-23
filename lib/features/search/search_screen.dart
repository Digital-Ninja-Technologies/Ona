import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/destinations_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/destination_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Search destinations or countries',
            prefixIcon: Icon(LucideIcons.search, size: 18),
          ),
        ),
      ),
      body: SafeArea(
        child: query.trim().isEmpty
            ? Center(
                child: Text(
                  'Search for a destination',
                  style: AppTheme.poppins(color: AppColors.textSecondary),
                ),
              )
            : results.when(
                data: (items) => items.isEmpty
                    ? Center(
                        child: Text(
                          'No results for "$query"',
                          style: AppTheme.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final destination = items[index];
                          return Row(
                            children: [
                              Expanded(
                                child: DestinationCard(
                                  destination: destination,
                                  width: double.infinity,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Search failed. Try again.',
                    style: AppTheme.poppins(color: AppColors.error),
                  ),
                ),
              ),
      ),
    );
  }
}
