import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

const _interestOptions = [
  'Beaches',
  'Mountains',
  'Culture & History',
  'Food & Dining',
  'Adventure',
  'Nightlife',
  'Nature & Wildlife',
  'Shopping',
  'Wellness',
  'Photography',
];

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  final Set<String> _selected = {};
  bool _isSaving = false;

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    final client = ref.read(supabaseProvider);
    final userId = client.auth.currentUser?.id;
    try {
      if (userId != null) {
        await client
            .from('profiles')
            .update({'interests': _selected.toList()})
            .eq('id', userId);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        context.go('/tabs/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What are you into?",
                style: AppTheme.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick a few interests so we can tailor recommendations for you.',
                style: AppTheme.poppins(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _interestOptions.map((interest) {
                      final isSelected = _selected.contains(interest);
                      return ChoiceChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selected.add(interest);
                            } else {
                              _selected.remove(interest);
                            }
                          });
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: AppTheme.poppins(
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _finish,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_selected.isEmpty ? 'Skip for now' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
