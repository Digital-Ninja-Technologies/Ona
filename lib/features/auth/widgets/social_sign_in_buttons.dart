import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../auth_controller.dart';

/// "Continue with Google" / "Continue with Apple" buttons for the sign-in
/// and sign-up screens, styled per each platform's own brand guidelines
/// (white pill + "G" mark for Google, black pill + Apple glyph for Apple)
/// rather than matching the app's own palette — these buttons need to read
/// as the platform's official entry point, not as an Ọ̀nà-branded control.
///
/// Apple's button only renders where the native flow is actually available
/// (iOS/macOS), per [SignInWithApple.isAvailable].
class SocialSignInButtons extends ConsumerStatefulWidget {
  const SocialSignInButtons({super.key});

  @override
  ConsumerState<SocialSignInButtons> createState() =>
      _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends ConsumerState<SocialSignInButtons> {
  bool _isAppleAvailable = false;
  _SocialProvider? _submitting;
  String? _error;

  @override
  void initState() {
    super.initState();
    SignInWithApple.isAvailable().then((available) {
      if (mounted) setState(() => _isAppleAvailable = available);
    });
  }

  Future<void> _signIn(
    _SocialProvider provider,
    Future<AuthResponse> Function() signIn,
  ) async {
    setState(() {
      _submitting = provider;
      _error = null;
    });
    try {
      await signIn();
      if (mounted) context.go('/tabs/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(authControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.25)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: AppTheme.poppins(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ).copyWith(letterSpacing: 1.2),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.25)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SocialButton(
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          borderColor: const Color(0xFFDADCE0),
          leading: const _GoogleLogo(size: 20),
          isLoading: _submitting == _SocialProvider.google,
          enabled: _submitting == null,
          onPressed: () =>
              _signIn(_SocialProvider.google, controller.signInWithGoogle),
        ),
        if (_isAppleAvailable) ...[
          const SizedBox(height: 12),
          _SocialButton(
            label: 'Continue with Apple',
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: const Icon(Icons.apple, size: 22, color: Colors.white),
            isLoading: _submitting == _SocialProvider.apple,
            enabled: _submitting == null,
            onPressed: () =>
                _signIn(_SocialProvider.apple, controller.signInWithApple),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _error!,
              style: AppTheme.poppins(color: const Color(0xFFFF8A75)),
            ),
          ),
        ],
      ],
    );
  }
}

enum _SocialProvider { google, apple }

/// A platform sign-in button rendered as a solid pill, per Google's and
/// Apple's own button guidelines (as opposed to the app's usual outlined
/// buttons, which would make these read as Ọ̀nà-styled rather than
/// recognizable platform entry points).
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.leading,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final Widget leading;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor.withValues(alpha: enabled ? 1 : 0.6),
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    leading,
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: AppTheme.poppins(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The Google "G" mark: a four-color ring (blue/green/yellow/red) with the
/// blue crossbar, drawn in code so the button doesn't need a bundled asset.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    void arc(double startDegrees, double sweepDegrees, Color color) {
      canvas.drawArc(
        rect,
        startDegrees * 3.1415926535 / 180,
        sweepDegrees * 3.1415926535 / 180,
        false,
        paint..color = color,
      );
    }

    arc(-45, 90, _blue);
    arc(45, 90, _green);
    arc(135, 90, _yellow);
    arc(225, 90, _red);

    // The crossbar of the "G", extending from the center out to the right
    // edge of the ring, in the same blue as the right-hand arc.
    final barPaint = Paint()..color = _blue;
    final barHeight = strokeWidth * 0.9;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2 - strokeWidth * 0.15,
        size.height / 2 - barHeight / 2,
        size.width / 2 - strokeWidth * 0.15,
        barHeight,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
