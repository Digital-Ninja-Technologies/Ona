import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The app's branded loading indicator — the Ọ̀nà logo animation looping in
/// a Deep Green badge, with an optional [label] underneath. Use it for
/// page- and section-level waits (where a spinner would otherwise sit in a
/// `Center`); keep the plain `CircularProgressIndicator` for tiny inline
/// spots like buttons.
///
/// All instances share one muted, looping [VideoPlayerController] (created
/// on first use, never disposed — like any long-lived app asset), so several
/// loaders on screen at once cost only one video decoder.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.label, this.size = 84});

  final String? label;
  final double size;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  static VideoPlayerController? _controller;
  static Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture ??= _initialize();
    _initFuture!.whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  static Future<void> _initialize() async {
    final controller = VideoPlayerController.asset(
      'assets/brand/ona-logo-animation.mp4',
    );
    _controller = controller;
    await controller.initialize();
    await controller.setVolume(0);
    await controller.setLooping(true);
    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.size * 0.28),
          child: Container(
            width: widget.size,
            height: widget.size,
            color: AppColors.primaryDark,
            alignment: Alignment.center,
            child: ready
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      // The mark sits in the middle ~15% of the frame, so
                      // zoom into the centre rather than showing a mostly
                      // empty green rectangle.
                      child: Transform.scale(
                        scale: 2.6,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/brand/ona-mark-on-dark.png',
                    width: widget.size * 0.5,
                    height: widget.size * 0.5,
                    fit: BoxFit.contain,
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
