import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';

/// Plays the Ọ̀nà brand logo animation once on a Deep Green backdrop that
/// matches the animation's own background, then continues into the app.
/// Tappable to skip, and falls back to a timeout in case playback never
/// starts (codec issues, slow devices, etc.) so nobody gets stuck here.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _init();
    Future.delayed(const Duration(seconds: 8), _next);
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset(
      'assets/brand/ona-logo-animation.mp4',
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setVolume(0);
      controller.addListener(_onTick);
      await controller.play();
      setState(() {});
    } catch (_) {
      _next();
    }
  }

  void _onTick() {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;
    if (!value.isPlaying &&
        value.position >= value.duration &&
        value.duration > Duration.zero) {
      _next();
    }
  }

  void _next() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/');
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return GestureDetector(
      onTap: _next,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: ready
            ? Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
