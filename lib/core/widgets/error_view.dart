import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The app's standard "something went wrong" state — an icon, a friendly
/// message, and an optional retry action. Use this instead of a bare error
/// [Text] wherever an [AsyncValue.when] `error` branch (or any failed load)
/// needs to show something to the user.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  /// A short, user-facing description of what failed. Never pass a raw
  /// exception's `toString()` here — write a plain-language message instead.
  final String message;

  /// Called when the user taps "Try again". Omit to hide the button (e.g.
  /// for a one-off action that can't simply be repeated).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.cloudOff,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
