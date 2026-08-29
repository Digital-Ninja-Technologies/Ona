import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';

/// Shown wherever a place/destination has no photo — or its image failed to
/// load — instead of an empty gray box. Loops the brand logo animation
/// (the same asset the splash screen plays once) muted and cropped to fill
/// whatever size it's given.
///
/// All instances share one [VideoPlayerController] (lazily created on first
/// use and never disposed, like any other long-lived app asset) since
/// several of these can appear on screen at once — e.g. a grid of AI place
/// suggestions where none has a photo yet — and starting a separate decoder
/// per tile would be wasteful.
class NoImagePlaceholder extends StatefulWidget {
  const NoImagePlaceholder({super.key});

  @override
  State<NoImagePlaceholder> createState() => _NoImagePlaceholderState();
}

class _NoImagePlaceholderState extends State<NoImagePlaceholder> {
  static VideoPlayerController? _sharedController;
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
    _sharedController = controller;
    await controller.initialize();
    await controller.setVolume(0);
    await controller.setLooping(true);
    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _sharedController;
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: controller != null && controller.value.isInitialized
          ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
