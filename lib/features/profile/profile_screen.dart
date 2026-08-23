import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: AppTheme.fredoka(fontSize: 28, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(email, style: AppTheme.poppins(fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            const Divider(),
            _ProfileMenuItem(icon: LucideIcons.heart, label: 'Wishlist'),
            _ProfileMenuItem(icon: LucideIcons.map, label: 'My Itineraries'),
            _ProfileMenuItem(
              icon: LucideIcons.bookmark,
              label: 'Saved Destinations',
            ),
            _ProfileMenuItem(icon: LucideIcons.settings, label: 'Settings'),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider).signOut();
                  if (context.mounted) context.go('/onboarding/welcome');
                },
                icon: const Icon(LucideIcons.logOut, color: AppColors.error),
                label: Text(
                  'Log Out',
                  style: AppTheme.poppins(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTheme.poppins()),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Coming soon')));
      },
    );
  }
}
