import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/agents_repository.dart';
import '../../core/data/profile_repository.dart';
import '../../core/data/storage_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/count_stat.dart';
import '../../core/widgets/image_loading_placeholder.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (file == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final Uint8List bytes = await file.readAsBytes();
      final extension = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpg';
      final imageUrl = await ref
          .read(storageRepositoryProvider)
          .uploadImage(bytes, extension: extension);
      await ref
          .read(profileRepositoryProvider)
          .updateProfileImage(imageUrl);
      ref.invalidate(myProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your photo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final profileAsync = ref.watch(myProfileProvider);
    final profileImage = profileAsync.valueOrNull?.profileImage;
    final myAgentProfile = ref.watch(myAgentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: ClipOval(
                    child: profileImage != null
                        ? CachedNetworkImage(
                            imageUrl: profileImage,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const ImageLoadingPlaceholder(
                                  background: AppColors.primary,
                                ),
                            errorWidget: (context, url, error) => Text(
                              initial,
                              style: AppTheme.fredoka(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            initial,
                            style: AppTheme.fredoka(
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.gold,
                      child: _uploadingPhoto
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              LucideIcons.camera,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(email, style: AppTheme.poppins(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: [
                CountStat(
                  count: profileAsync.valueOrNull?.followersCount ?? 0,
                  label: 'Followers',
                ),
                const SizedBox(width: 24),
                CountStat(
                  count: profileAsync.valueOrNull?.followingCount ?? 0,
                  label: 'Following',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            _ProfileMenuItem(
              icon: LucideIcons.heart,
              label: 'Wishlist',
              onTap: () => context.push('/wishlist'),
            ),
            _ProfileMenuItem(
              icon: LucideIcons.map,
              label: 'My Itineraries',
              onTap: () => context.go('/tabs/itineraries'),
            ),
            _ProfileMenuItem(
              icon: LucideIcons.compass,
              label: 'Travel Essentials',
              onTap: () => context.push('/essentials'),
            ),
            _ProfileMenuItem(
              icon: LucideIcons.sparkles,
              label: 'Ask Ọ̀nà AI',
              onTap: () => context.push('/ai-assistant'),
            ),
            _ProfileMenuItem(
              icon: LucideIcons.settings,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),
            _ProfileMenuItem(
              icon: LucideIcons.briefcase,
              label: myAgentProfile != null
                  ? 'My Agent Profile'
                  : 'Register as an Agent',
              onTap: () => myAgentProfile != null
                  ? context.push('/travel-agent/${myAgentProfile.id}')
                  : context.push('/agent/register'),
            ),
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
  const _ProfileMenuItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTheme.poppins()),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Coming soon')));
          },
    );
  }
}
