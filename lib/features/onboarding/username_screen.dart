import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/profile_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

/// Shown once, right after signing up/in, to whoever hasn't chosen a
/// username yet (see needsUsernameProvider — this fires the same way for
/// email, Google, and Apple sign-in, and for pre-existing accounts). Not
/// skippable: the @handle is what shows on every post from here on.
class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final username = _controller.text.trim();
    try {
      await ref.read(profileRepositoryProvider).updateUsername(username);
      await ref.read(authControllerProvider).updateUsernameMetadata(username);
      if (mounted) context.go('/tabs/home');
    } on UsernameTakenException {
      setState(() => _error = 'That username is taken. Try another.');
    } catch (_) {
      setState(() => _error = 'Could not save your username. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a username',
                  style: AppTheme.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is your @handle — it shows on every post, comment, '
                  'and repost you make. You can change it later in Settings.',
                  style: AppTheme.poppins(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                  ],
                  decoration: const InputDecoration(
                    prefixText: '@',
                    hintText: 'yourname',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (!_usernamePattern.hasMatch(trimmed)) {
                      return '3-20 letters, numbers, or underscores';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
