import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/agents_repository.dart';
import '../../core/data/storage_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Splits a comma-separated field into a trimmed, non-empty list — used for
/// both specialties and languages so the two fields behave identically.
List<String> _splitTags(String value) => value
    .split(',')
    .map((tag) => tag.trim())
    .where((tag) => tag.isNotEmpty)
    .toList();

/// Lets a signed-in user apply to become a travel agent. Submitting emails
/// the details to the Ona team for review — it does not create a public
/// listing itself, so nothing shows up on the agent page until approved.
class RegisterAgentScreen extends ConsumerStatefulWidget {
  const RegisterAgentScreen({super.key, this.plan});

  /// The verification plan chosen on [AgentConductScreen] — e.g.
  /// "Standard — \$105/month" — included in the emailed application.
  final String? plan;

  @override
  ConsumerState<RegisterAgentScreen> createState() =>
      _RegisterAgentScreenState();
}

class _RegisterAgentScreenState extends ConsumerState<RegisterAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _languagesController = TextEditingController();
  final _yearsController = TextEditingController();

  ({Uint8List bytes, String extension})? _pickedImage;
  bool _submitting = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _bioController.dispose();
    _specialtiesController.dispose();
    _languagesController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final extension = file.name.contains('.')
        ? file.name.split('.').last
        : 'jpg';
    setState(() => _pickedImage = (bytes: bytes, extension: extension));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await ref
            .read(storageRepositoryProvider)
            .uploadImage(
              _pickedImage!.bytes,
              extension: _pickedImage!.extension,
            );
      }
      await ref
          .read(agentsRepositoryProvider)
          .submitAgentApplication(
            businessName: _businessNameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            specialties: _splitTags(_specialtiesController.text),
            languages: _splitTags(_languagesController.text),
            yearsExperience: int.tryParse(_yearsController.text.trim()),
            imageUrl: imageUrl,
            plan: widget.plan,
          );
      if (mounted) await _showConfirmation();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send your application.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showConfirmation() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Application Submitted'),
        content: Text(
          "Thanks for applying to become an Ọ̀nà agent. We'll review your "
          "details and follow up by email with the payment process and any "
          "documents we need — usually within 2–3 business days.",
          style: AppTheme.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/tabs/profile');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as an Agent')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                "Tell us about your travel business. We'll review your "
                "application and email you once it's approved — your "
                "profile won't be public until then.",
                style: AppTheme.poppins(color: AppColors.textSecondary),
              ),
              if (widget.plan != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.badgeCheck,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Applying for: ${widget.plan}',
                          style: AppTheme.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: _pickedImage != null
                              ? Image.memory(
                                  _pickedImage!.bytes,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: AppColors.surface,
                                  child: const Icon(
                                    LucideIcons.building2,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.gold,
                          child: const Icon(
                            LucideIcons.camera,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Business name',
                style: AppTheme.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Lagos Travel Co.',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a business name.'
                    : null,
              ),
              const SizedBox(height: 20),
              Text('Bio', style: AppTheme.poppins(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tell travelers a bit about what you do...',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Specialties',
                style: AppTheme.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _specialtiesController,
                decoration: const InputDecoration(
                  hintText: 'Beach holidays, Luxury travel, Safaris',
                  helperText: 'Separate with commas',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Languages',
                style: AppTheme.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _languagesController,
                decoration: const InputDecoration(
                  hintText: 'English, Yoruba, French',
                  helperText: 'Separate with commas',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Years of experience',
                style: AppTheme.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yearsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 5'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return int.tryParse(value.trim()) == null
                      ? 'Enter a whole number.'
                      : null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
