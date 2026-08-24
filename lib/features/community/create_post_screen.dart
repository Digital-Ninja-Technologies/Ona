import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/community_repository.dart';
import '../../core/data/storage_repository.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  String _type = 'story';
  final _contentController = TextEditingController();
  ({Uint8List bytes, String extension})? _pickedImage;
  bool _submitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final extension = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    setState(() => _pickedImage = (bytes: bytes, extension: extension));
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something to share first.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await ref
            .read(storageRepositoryProvider)
            .uploadImage(_pickedImage!.bytes, extension: _pickedImage!.extension);
      }
      await ref
          .read(communityRepositoryProvider)
          .createPost(
            type: _type,
            content: _contentController.text.trim(),
            imageUrl: imageUrl,
          );
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not publish your post.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 8,
              children: _postTypeOptions.map((entry) {
                final (value, label) = entry;
                return ChoiceChip(
                  label: Text(label),
                  selected: _type == value,
                  onSelected: (_) => setState(() => _type = value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Share a story, tip, or ask a question...',
              ),
            ),
            const SizedBox(height: 16),
            if (_pickedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _pickedImage!.bytes,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(LucideIcons.image),
                label: const Text('Add a photo (optional)'),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
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
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}

const _postTypeOptions = [
  ('story', 'Story'),
  ('tip', 'Tip'),
  ('question', 'Question'),
];
