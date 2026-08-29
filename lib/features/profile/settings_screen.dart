import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/profile_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _nameInitialized = false;
  bool _savingName = false;
  String? _nameError;

  final _usernameFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _usernameInitialized = false;
  bool _savingUsername = false;
  String? _usernameError;

  final _passwordFormKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _savingPassword = false;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a name.');
      return;
    }
    setState(() {
      _savingName = true;
      _nameError = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateName(name);
      await ref.read(authControllerProvider).updateDisplayName(name);
      ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Name updated.')));
      }
    } catch (_) {
      if (mounted) setState(() => _nameError = 'Could not update your name.');
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _saveUsername() async {
    if (!_usernameFormKey.currentState!.validate()) return;
    setState(() {
      _savingUsername = true;
      _usernameError = null;
    });
    final username = _usernameController.text.trim();
    try {
      await ref.read(profileRepositoryProvider).updateUsername(username);
      await ref.read(authControllerProvider).updateUsernameMetadata(username);
      ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Username updated.')));
      }
    } on UsernameTakenException {
      setState(() => _usernameError = 'That username is taken.');
    } catch (_) {
      setState(() => _usernameError = 'Could not update your username.');
    } finally {
      if (mounted) setState(() => _savingUsername = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _savingPassword = true;
      _passwordError = null;
    });
    try {
      await ref
          .read(authControllerProvider)
          .updatePassword(_passwordController.text);
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password updated.')));
      }
    } on AuthException catch (e) {
      setState(() => _passwordError = e.message);
    } catch (_) {
      setState(() => _passwordError = 'Could not update your password.');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(myProfileProvider);

    // Prefill the name field once, from whichever name we have — don't
    // stomp on what the user is actively typing on every rebuild.
    if (!_nameInitialized) {
      final existingName =
          profileAsync.valueOrNull?.name ??
          user?.userMetadata?['name'] as String?;
      if (existingName != null) _nameController.text = existingName;
      _nameInitialized = true;
    }
    if (!_usernameInitialized) {
      final existingUsername =
          profileAsync.valueOrNull?.username ??
          user?.userMetadata?['username'] as String?;
      if (existingUsername != null) {
        _usernameController.text = existingUsername;
      }
      _usernameInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Account', style: AppTheme.fredoka(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              user?.email ?? '',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text('Name', style: AppTheme.poppins(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Your name'),
            ),
            if (_nameError != null) ...[
              const SizedBox(height: 8),
              Text(_nameError!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _savingName ? null : _saveName,
                child: _savingName
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save name'),
              ),
            ),
            const SizedBox(height: 32),
            Text('Username', style: AppTheme.fredoka(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Shown on every post, comment, and repost you make.',
              style: AppTheme.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Form(
              key: _usernameFormKey,
              child: TextFormField(
                controller: _usernameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                decoration: const InputDecoration(
                  prefixText: '@',
                  hintText: 'yourname',
                ),
                validator: (value) {
                  if (!_usernamePattern.hasMatch(value?.trim() ?? '')) {
                    return '3-20 letters, numbers, or underscores';
                  }
                  return null;
                },
              ),
            ),
            if (_usernameError != null) ...[
              const SizedBox(height: 8),
              Text(
                _usernameError!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _savingUsername ? null : _saveUsername,
                child: _savingUsername
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save username'),
              ),
            ),
            const SizedBox(height: 32),
            Text('Password', style: AppTheme.fredoka(fontSize: 16)),
            const SizedBox(height: 12),
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'New password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      hintText: 'Confirm new password',
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _passwordError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _savingPassword ? null : _savePassword,
                      child: _savingPassword
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update password'),
                    ),
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
