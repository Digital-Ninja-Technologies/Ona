import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/ai_assistant_repository.dart';
import '../../core/data/countries.dart';
import '../../core/data/location_repository.dart';
import '../../core/models/travel_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/country_picker.dart';
import '../../core/widgets/error_view.dart';

class VisaRequirementsScreen extends ConsumerStatefulWidget {
  const VisaRequirementsScreen({super.key});

  @override
  ConsumerState<VisaRequirementsScreen> createState() =>
      _VisaRequirementsScreenState();
}

class _VisaRequirementsScreenState
    extends ConsumerState<VisaRequirementsScreen> {
  String? _from;
  String? _to;

  @override
  void initState() {
    super.initState();
    // Best-effort: default the passport country to wherever the user is.
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFrom());
  }

  Future<void> _prefillFrom() async {
    try {
      final name = await ref
          .read(locationRepositoryProvider)
          .fetchCurrentLocationName();
      final country = name.contains(',') ? name.split(',').last.trim() : name;
      final match = kCountries.firstWhere(
        (c) => c.toLowerCase() == country.toLowerCase(),
        orElse: () => '',
      );
      if (mounted && match.isNotEmpty && _from == null) {
        setState(() => _from = match);
      }
    } catch (_) {
      // Silent — the user can pick a country manually.
    }
  }

  Future<void> _pick({required bool isFrom}) async {
    final selected = await showCountryPicker(
      context,
      current: isFrom ? _from : _to,
    );
    if (selected != null) {
      setState(() => isFrom ? _from = selected : _to = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = _from;
    final to = _to;
    final ready = from != null && to != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Visa Requirements')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Check tourist visa rules for any passport and destination',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _CountryField(
              label: 'Passport / country of residence',
              value: from,
              placeholder: 'Select your country',
              icon: LucideIcons.bookUser,
              onTap: () => _pick(isFrom: true),
            ),
            const SizedBox(height: 12),
            Center(
              child: Icon(
                LucideIcons.arrowDown,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            _CountryField(
              label: 'Destination',
              value: to,
              placeholder: 'Select a destination',
              icon: LucideIcons.plane,
              onTap: () => _pick(isFrom: false),
            ),
            const SizedBox(height: 24),
            if (!ready)
              Text(
                'Pick both countries to see the visa requirements.',
                style: AppTheme.poppins(color: AppColors.textSecondary),
              )
            else if (from == to)
              Text(
                'Pick two different countries.',
                style: AppTheme.poppins(color: AppColors.textSecondary),
              )
            else
              ref
                  .watch(
                    visaRequirementProvider((
                      fromCountry: from,
                      toCountry: to,
                    )),
                  )
                  .when(
                    loading: () => const _Loading(),
                    error: (_, _) => ErrorView(
                      message: 'Could not load visa requirements',
                      onRetry: () => ref.invalidate(
                        visaRequirementProvider((
                          fromCountry: from,
                          toCountry: to,
                        )),
                      ),
                    ),
                    data: (visa) => visa.isEmpty
                        ? Text(
                            'No visa information found for this route. Check '
                            'the destination\'s official immigration site.',
                            style: AppTheme.poppins(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : _Result(from: from, to: to, visa: visa),
                  ),
          ],
        ),
      ),
    );
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: AppTheme.fredoka(
                      fontSize: 16,
                      color: value == null
                          ? AppColors.textSecondary
                          : AppColors.text,
                    ),
                  ),
                ),
                const Icon(LucideIcons.chevronDown, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.from, required this.to, required this.visa});

  final String from;
  final String to;
  final VisaRequirement visa;

  Color get _badgeColor {
    switch (visa.requirement.toLowerCase()) {
      case 'visa-free':
        return AppColors.verified;
      case 'visa on arrival':
      case 'evisa':
        return AppColors.gold;
      case 'visa required':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _badgeColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$from → $to',
                style: AppTheme.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                visa.requirement,
                style: AppTheme.fredoka(fontSize: 20, color: _badgeColor),
              ),
              if (visa.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(visa.summary, style: AppTheme.poppins(fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Fact(LucideIcons.calendarClock, 'Allowed stay', visa.allowedStay),
        _Fact(LucideIcons.wallet, 'Cost', visa.cost),
        _Fact(LucideIcons.hourglass, 'Processing time', visa.processingTime),
        _Fact(LucideIcons.fileText, 'How to apply', visa.howToApply),
        if (visa.documents.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Documents', style: AppTheme.fredoka(fontSize: 15)),
          const SizedBox(height: 8),
          for (final doc in visa.documents) _Bullet(doc),
        ],
        if (visa.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Good to know', style: AppTheme.fredoka(fontSize: 15)),
          const SizedBox(height: 8),
          for (final note in visa.notes) _Bullet(note),
        ],
        const SizedBox(height: 16),
        Text(
          'AI-generated from recent web results — always confirm with the '
          "destination's official immigration authority before you travel.",
          style: AppTheme.poppins(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.poppins(fontSize: 13)),
              ],
            ),
          ),
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
            'Checking current visa rules...',
            style: AppTheme.poppins(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
