import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A "123 Followers"-style stat, used on both the signed-in user's own
/// profile and another user's profile screen.
class CountStat extends StatelessWidget {
  const CountStat({super.key, required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$count',
          style: AppTheme.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.poppins(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
