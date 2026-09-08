import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/ai_assistant_repository.dart';
import '../../core/data/location_repository.dart';
import '../../core/models/travel_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/error_view.dart';
import 'widgets/essentials_location_bar.dart';

class SimCardsScreen extends ConsumerStatefulWidget {
  const SimCardsScreen({super.key});

  @override
  ConsumerState<SimCardsScreen> createState() => _SimCardsScreenState();
}

class _SimCardsScreenState extends ConsumerState<SimCardsScreen> {
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
      appBar: AppBar(title: const Text('Local SIM Cards')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Local carriers, eSIM options and current prices for staying '
              'connected',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            EssentialsLocationBar(
              location: location,
              resolving: _resolvingLocation,
              hintText: 'Enter a country or city...',
              onSubmitted: (value) => setState(() => _location = value),
              onUseMyLocation: () => _useMyLocation(false),
            ),
            const SizedBox(height: 20),
            if (location == null)
              Text(
                'Set a location above to see connectivity options.',
                style: AppTheme.poppins(color: AppColors.textSecondary),
              )
            else
              ref
                  .watch(simGuideProvider(location))
                  .when(
                    loading: () => const AppLoaderCenter(
                      label: 'Checking the web for the latest...',
                    ),
                    error: (_, _) => ErrorView(
                      message: 'Could not load SIM options for "$location"',
                      onRetry: () => ref.invalidate(simGuideProvider(location)),
                    ),
                    data: (guide) => guide.isEmpty
                        ? Text(
                            'No connectivity info found for "$location".',
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

  final SimGuide guide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (guide.summary.isNotEmpty) ...[
          Text(guide.summary, style: AppTheme.poppins(fontSize: 13)),
          const SizedBox(height: 20),
        ],
        if (guide.options.isNotEmpty) ...[
          _SectionTitle(LucideIcons.wifi, 'Options'),
          const SizedBox(height: 10),
          for (final option in guide.options) _OptionCard(option: option),
          const SizedBox(height: 10),
        ],
        if (guide.whereToBuy.isNotEmpty) ...[
          _SectionTitle(LucideIcons.shoppingBag, 'Where to buy'),
          const SizedBox(height: 10),
          for (final item in guide.whereToBuy) _Bullet(item),
          const SizedBox(height: 10),
        ],
        if (guide.tips.isNotEmpty) ...[
          _SectionTitle(LucideIcons.lightbulb, 'Setup tips'),
          const SizedBox(height: 10),
          for (final tip in guide.tips) _Bullet(tip),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option});

  final SimOption option;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  option.provider,
                  style: AppTheme.fredoka(fontSize: 15),
                ),
              ),
              if (option.type.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    option.type,
                    style: AppTheme.poppins(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (option.typicalPrice.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              option.typicalPrice,
              style: AppTheme.fredoka(fontSize: 14, color: AppColors.primary),
            ),
          ],
          if (option.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              option.notes,
              style: AppTheme.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
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
