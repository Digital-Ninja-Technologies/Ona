import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shown by [CachedNetworkImage]'s `placeholder` while a network image is
/// still downloading — a small centered spinner over a background tint, so
/// a slow-loading photo reads as "loading" rather than empty space. Reuse
/// [background] to match whatever fallback color the same image's
/// `errorWidget` uses.
class ImageLoadingPlaceholder extends StatelessWidget {
  const ImageLoadingPlaceholder({
    super.key,
    this.background = AppColors.surface,
  });

  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
