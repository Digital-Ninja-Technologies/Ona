import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// The app's first-run flow: two swipeable feature intro slides, then the
/// welcome slide with the actual sign-up/sign-in entry points.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _pageCount = 3;

  final _pageController = PageController();
  int _page = 0;

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _page = index),
                children: const [
                  _IntroSlide(
                    icon: LucideIcons.compass,
                    eyebrow: 'DISCOVER',
                    title: 'Places worth\nthe trip',
                    body:
                        'AI-curated suggestions and real traveler reviews '
                        "help you find spots you'll actually love.",
                  ),
                  _IntroSlide(
                    icon: LucideIcons.listChecks,
                    eyebrow: 'PLAN',
                    title: 'Every detail,\nsorted',
                    body:
                        'Build itineraries, book experiences, and get '
                        'instant answers from your AI travel agent.',
                  ),
                  _WelcomeSlide(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pageCount,
                  (index) => _PageDot(active: index == _page),
                ),
              ),
            ),
            if (_page < _pageCount - 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => _goToPage(_pageCount - 1),
                      child: Text(
                        'Skip',
                        style: AppTheme.poppins(
                          color: AppColors.cream.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _goToPage(_page + 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.charcoal,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(LucideIcons.arrowRight, size: 20),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.gold : AppColors.cream.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// An intro slide split evenly top/bottom: a solid-color panel with a large
/// icon fills the top half, and the copy sits left-aligned in the bottom
/// half — no photography, just brand color and type.
class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: AppColors.routeGreen,
            child: Center(child: _FloatingIcon(icon: icon)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppTheme.poppins(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ).copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTheme.fredoka(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cream,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: AppTheme.poppins(
                    color: AppColors.sand.withValues(alpha: 0.85),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The intro-slide icon badge, gently floating and pulsing in a continuous
/// loop so the top panel doesn't sit completely static while a slide is on
/// screen.
class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon({required this.icon});

  final IconData icon;

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -10 * t),
          child: Transform.scale(scale: 0.96 + 0.08 * t, child: child),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, size: 64, color: AppColors.gold),
      ),
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          Image.asset(
            'assets/brand/ona-mark-on-dark.png',
            width: 92,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            'Ọ̀nà',
            style: AppTheme.fredoka(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              color: AppColors.cream,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Discover destinations, plan itineraries, and travel\nwith confidence — all in one place.',
            style: AppTheme.poppins(
              color: AppColors.sand.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/auth/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.charcoal,
              ),
              child: const Text('Get Started'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/auth/signin'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.cream,
                side: BorderSide(color: AppColors.sand.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'I already have an account',
                style: AppTheme.poppins(
                  fontWeight: FontWeight.w500,
                  color: AppColors.cream,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
