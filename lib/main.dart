import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  runApp(const ProviderScope(child: OnaApp()));
}

class OnaApp extends ConsumerWidget {
  const OnaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseConfig.isConfigured) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: const _SupabaseNotConfiguredScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Ọ̀nà',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

class _SupabaseNotConfiguredScreen extends StatelessWidget {
  const _SupabaseNotConfiguredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/brand/ona-mark.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                'Supabase is not configured',
                style: AppTheme.fredoka(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Run with --dart-define=SUPABASE_URL=... and '
                '--dart-define=SUPABASE_PUBLISHABLE_KEY=... after creating a '
                'Supabase project and applying supabase/migrations/0001_init.sql. '
                'See README.md.',
                textAlign: TextAlign.center,
                style: AppTheme.poppins(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
