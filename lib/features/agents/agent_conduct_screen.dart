import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

const _conductPoints = [
  'Be honest and transparent about pricing, availability, and what\'s '
      'actually included in every offer.',
  'Respond to traveler messages and booking requests promptly and '
      'professionally.',
  'Never request or accept payment outside of Ọ̀nà\'s approved channels.',
  'Protect travelers\' personal and payment information — never share it '
      'with third parties.',
  'Honor every itinerary, booking, and cancellation policy you publish.',
  'Treat all travelers with respect, regardless of background or '
      'destination.',
];

/// A billing cycle for the (single) verification fee — not separate fee
/// tiers, just monthly vs. annual billing of the same fee.
class _BillingCycle {
  const _BillingCycle(this.label, this.price, this.unit, this.description);
  final String label;
  final String price;
  final String unit;
  final String description;

  String get summary => '$label — \$$price/$unit';
}

const _billingCycles = [
  _BillingCycle('Monthly', '15', 'month', 'Billed every month.'),
  _BillingCycle(
    'Annual',
    '165',
    'year',
    'Billed once a year — save \$15 versus paying monthly.',
  ),
];

/// Shown before the agent application form — the code of conduct every
/// agent must follow, and the verification fee. Selecting a billing cycle
/// and agreeing is required before "Proceed" opens the form.
class AgentConductScreen extends StatefulWidget {
  const AgentConductScreen({super.key});

  @override
  State<AgentConductScreen> createState() => _AgentConductScreenState();
}

class _AgentConductScreenState extends State<AgentConductScreen> {
  int? _selectedCycle;
  bool _agreed = false;

  bool get _canProceed => _selectedCycle != null && _agreed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become an Ọ̀nà Agent')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Code of Conduct',
                    style: AppTheme.fredoka(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Every agent listed on Ọ̀nà is expected to:',
                    style: AppTheme.poppins(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  ..._conductPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              LucideIcons.checkCircle2,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(point, style: AppTheme.poppins()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Verification Fee',
                    style: AppTheme.fredoka(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "There's a single verification fee once your "
                    "application is approved — choose how you'd like to "
                    "be billed:",
                    style: AppTheme.poppins(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  ..._billingCycles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cycle = entry.value;
                    final selected = _selectedCycle == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _selectedCycle = index),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? LucideIcons.circleDot
                                    : LucideIcons.circle,
                                size: 20,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${cycle.label} — \$${cycle.price}/'
                                      '${cycle.unit}',
                                      style: AppTheme.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cycle.description,
                                      style: AppTheme.poppins(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (value) =>
                                setState(() => _agreed = value ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'I have read and agree to the Code of '
                                'Conduct and verification fee above.',
                                style: AppTheme.poppins(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed
                      ? () => context.push(
                          '/agent/register',
                          extra: _billingCycles[_selectedCycle!].summary,
                        )
                      : null,
                  child: const Text('Proceed'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
