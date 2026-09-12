import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The app's branded loading indicator — a single Way Gold dot, breathing on
/// a Deep Green badge, with an optional [label] underneath. Use it for
/// page- and section-level waits (where a spinner would otherwise sit in a
/// `Center`); keep the plain `CircularProgressIndicator` for tiny inline
/// spots like buttons.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.label, this.size = 84});

  final String? label;
  final double size;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(widget.size * 0.28),
          ),
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Opacity(
              opacity: 0.55 + _pulse.value * 0.45,
              child: Transform.scale(
                scale: 0.75 + _pulse.value * 0.25,
                child: child,
              ),
            ),
            child: Container(
              width: widget.size * 0.26,
              height: widget.size * 0.26,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.label!,
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
