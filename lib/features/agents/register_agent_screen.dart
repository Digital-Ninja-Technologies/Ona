import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/agents_repository.dart';
import '../../core/data/storage_repository.dart';
import '../../core/models/travel_agent.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Route target for `/agent/register` — resolves whether the signed-in user
/// already has an agent listing before deciding whether [RegisterAgentScreen]
/// starts blank (register) or prefilled (edit).
class RegisterAgentRoute extends ConsumerWidget {
  const RegisterAgentRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAgentAsync = ref.watch(myAgentProfileProvider);
    return myAgentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const RegisterAgentScreen(),
      data: (agent) => RegisterAgentScreen(existing: agent),
    );
  }
}

/// Splits a comma-separated field into a trimmed, non-empty list — used for
/// both specialties and languages so the two fields behave identically.
List<String> _splitTags(String value) => value
    .split(',')
    .map((tag) => tag.trim())
    .where((tag) => tag.isNotEmpty)
    .toList();

/// Lets a signed-in user register (or edit) their own travel-agent listing.
/// Submitting writes straight to the same `travel_agents` row the public
/// agents list and [AgentDetailScreen] read from, so what's typed here is
/// exactly what shows up on the agent's profile page.
class RegisterAgentScreen extends ConsumerStatefulWidget {
  const RegisterAgentScreen({super.key, this.existing});

  /// Non-null when editing an already-registered listing — prefills the
  /// form instead of starting blank.
  final TravelAgent? existing;

  @override
  ConsumerState<RegisterAgentScreen> createState() =>
      _RegisterAgentScreenState();
}

class _RegisterAgentScreenState extends ConsumerState<RegisterAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _businessNameController = TextEditingController(
    text: widget.existing?.businessName,
  );
  late final _bioController = TextEditingController(text: widget.existing?.bio);
  late final _specialtiesController = TextEditingController(
    text: widget.existing?.specialties.join(', '),
  );
  late final _languagesController = TextEditingController(
    text: widget.existing?.languages.join(', '),
  );
  late final _yearsController = TextEditingController(
    text: widget.existing?.yearsExperience?.toString(),
  );

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
      String? imageUrl = widget.existing?.imageUrl;
      if (_pickedImage != null) {
        imageUrl = await ref
            .read(storageRepositoryProvider)
            .uploadImage(
              _pickedImage!.bytes,
              extension: _pickedImage!.extension,
            );
      }
      final agent = await ref
          .read(agentsRepositoryProvider)
          .registerAsAgent(
            businessName: _businessNameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            specialties: _splitTags(_specialtiesController.text),
            languages: _splitTags(_languagesController.text),
            yearsExperience: int.tryParse(_yearsController.text.trim()),
            imageUrl: imageUrl,
          );
      ref.invalidate(myAgentProfileProvider);
      ref.invalidate(agentsListProvider);
      ref.invalidate(agentDetailProvider(agent.id));
      if (mounted) context.pushReplacement('/travel-agent/${agent.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your agent profile.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Agent Profile' : 'Register as an Agent'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'These details show up on your public agent profile — '
                'travelers will see them when they search for an agent to '
                'help plan their trip.',
                style: AppTheme.poppins(color: AppColors.textSecondary),
              ),
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
                              : widget.existing?.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.existing!.imageUrl!,
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
                      : Text(isEditing ? 'Save Changes' : 'Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
