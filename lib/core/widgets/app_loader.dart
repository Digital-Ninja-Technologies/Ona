import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The app's branded loading indicator — the Ọ̀nà icon animation looping on
/// its own Deep Green backdrop, with an optional [label] underneath. Use it
/// for page- and section-level waits (where a spinner would otherwise sit in
/// a `Center`); keep the plain `CircularProgressIndicator` for tiny inline
/// spots like buttons.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.label, this.size = 84});

  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Container(
            width: size,
            height: size,
            color: AppColors.primaryDark,
            alignment: Alignment.center,
            // The mark sits in the middle of a much larger square frame, so
            // zoom into the centre rather than showing a mostly empty green
            // square.
            child: Transform.scale(
              scale: 2.3,
              child: Image.asset(
                'assets/brand/ONA Icon Animation.gif',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 14),
          Text(
            label!,
            textAlign: TextAlign.center,
            style: AppTheme.poppins(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// [AppLoader] centred in the available space — the drop-in replacement for
/// `Center(child: CircularProgressIndicator())`.
class AppLoaderCenter extends StatelessWidget {
  const AppLoaderCenter({super.key, this.label, this.padding});

  final String? label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 40),
        child: AppLoader(label: label),
      ),
    );
  }
}
