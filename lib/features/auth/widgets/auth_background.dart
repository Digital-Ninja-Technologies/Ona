import 'package:flutter/material.dart';

/// Full-bleed image with a dark gradient overlay, matching the original
/// sign-in/sign-up screens' hero treatment.
class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.imageUrl,
    required this.child,
  });

  final String imageUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(imageUrl, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
