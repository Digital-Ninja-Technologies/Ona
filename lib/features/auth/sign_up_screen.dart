import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';
import 'widgets/auth_background.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _confirmationSent = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(authControllerProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          );
      if (!mounted) return;
      if (response.session != null) {
        // Email confirmation is off (or already satisfied) — we have a
        // real session, so continue straight into onboarding.
        context.go('/onboarding/interests');
      } else {
        // Supabase project requires email confirmation: signUp succeeded
        // but there's no session yet. Don't navigate anywhere that
        // requires sign-in — show a "check your email" state instead.
        setState(() => _confirmationSent = true);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not create your account. Try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        imageUrl:
            'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1',
        child: _confirmationSent
            ? _buildConfirmationSent(context)
            : _buildForm(context),
      ),
    );
  }

  Widget _buildConfirmationSent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/brand/ona-mark-on-dark.png',
            width: 40,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            'Check your email',
            style: AppTheme.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We've sent a confirmation link to "
            "${_emailController.text.trim()}. Tap it, then come back and "
            'sign in.',
            style: AppTheme.poppins(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/auth/signin'),
              child: const Text('Back to sign in'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Image.asset(
              'assets/brand/ona-mark-on-dark.png',
              width: 40,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              'Create your account',
              style: AppTheme.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start planning your next adventure',
              style: AppTheme.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(hintText: 'Full name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(hintText: 'Email'),
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign Up'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: AppTheme.poppins(color: Colors.white70),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: AppTheme.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
