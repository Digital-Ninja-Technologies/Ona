import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/ai_assistant_repository.dart';
import '../../core/data/location_repository.dart';
import '../../core/models/travel_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import 'widgets/essentials_location_bar.dart';

class FoodGuideScreen extends ConsumerStatefulWidget {
  const FoodGuideScreen({super.key});

  @override
  ConsumerState<FoodGuideScreen> createState() => _FoodGuideScreenState();
}

class _FoodGuideScreenState extends ConsumerState<FoodGuideScreen> {
  String? _location;
  bool _resolvingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation(true));
  }

  Future<void> _useMyLocation(bool silent) async {
    if (_resolvingLocation) return;
    setState(() => _resolvingLocation = true);
    try {
      final name = await ref
          .read(locationRepositoryProvider)
          .fetchCurrentLocationName();
      if (mounted) setState(() => _location = name);
    } catch (error) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;

    return Scaffold(
      appBar: AppBar(title: const Text('Local Food Guide')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Must-try dishes, local drinks, and dining tips for where you are',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            EssentialsLocationBar(
              location: location,
              resolving: _resolvingLocation,
              hintText: 'Enter a city or country...',
              onSubmitted: (value) => setState(() => _location = value),
              onUseMyLocation: () => _useMyLocation(false),
            ),
            const SizedBox(height: 20),
            if (location == null)
              Text(
                'Set a location above to see its food guide.',
                style: AppTheme.poppins(color: AppColors.textSecondary),
              )
            else
              ref
                  .watch(foodGuideProvider(location))
                  .when(
                    loading: () => const _Loading(),
                    error: (_, _) => ErrorView(
                      message: 'Could not load a food guide for "$location"',
                      onRetry: () =>
                          ref.invalidate(foodGuideProvider(location)),
                    ),
                    data: (guide) => guide.isEmpty
                        ? Text(
                            'No food guide found for "$location". Try a '
                            'nearby city.',
                            style: AppTheme.poppins(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : _Guide(guide: guide),
                  ),
          ],
        ),
      ),
    );
  }
}

class _Guide extends StatelessWidget {
  const _Guide({required this.guide});

  final FoodGuide guide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (guide.summary.isNotEmpty) ...[
          Text(guide.summary, style: AppTheme.poppins(fontSize: 13)),
          const SizedBox(height: 20),
        ],
        if (guide.dishes.isNotEmpty) ...[
          _SectionTitle(LucideIcons.utensilsCrossed, 'Must-try dishes'),
          const SizedBox(height: 10),
          for (final dish in guide.dishes)
            _ItemCard(
              name: dish.name,
              description: dish.description,
              footer: dish.whereToTry == null
                  ? null
                  : 'Try it at: ${dish.whereToTry}',
            ),
          const SizedBox(height: 10),
        ],
        if (guide.drinks.isNotEmpty) ...[
          _SectionTitle(LucideIcons.wine, 'Local drinks'),
          const SizedBox(height: 10),
          for (final drink in guide.drinks)
            _ItemCard(name: drink.name, description: drink.description),
          const SizedBox(height: 10),
        ],
        if (guide.tips.isNotEmpty) ...[
          _SectionTitle(LucideIcons.lightbulb, 'Dining tips'),
          const SizedBox(height: 10),
          for (final tip in guide.tips) _Bullet(tip),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.fredoka(fontSize: 16)),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.name,
    required this.description,
    this.footer,
  });

  final String name;
  final String description;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTheme.fredoka(fontSize: 15)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTheme.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    footer!,
                    style: AppTheme.poppins(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: AppTheme.poppins()),
          Expanded(child: Text(text, style: AppTheme.poppins(fontSize: 13))),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Checking the web for the latest...',
            style: AppTheme.poppins(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
