import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/reviews_repository.dart';
import '../../core/data/storage_repository.dart';
import '../../core/models/review.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key, required this.target, required this.title});

  final ReviewTarget target;
  final String title;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  bool _showForm = false;
  int _rating = 0;
  final _commentController = TextEditingController();
  final List<({Uint8List bytes, String extension})> _pickedImages = [];
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80, limit: 3);
    if (files.isEmpty) return;
    for (final file in files.take(3 - _pickedImages.length)) {
      final bytes = await file.readAsBytes();
      final extension = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpg';
      setState(() => _pickedImages.add((bytes: bytes, extension: extension)));
    }
  }

  Future<void> _submit() async {
    if (ref.read(currentUserProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to leave a review.')),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final imageUrls = <String>[];
      for (final image in _pickedImages) {
        final url = await ref
            .read(storageRepositoryProvider)
            .uploadImage(image.bytes, extension: image.extension);
        imageUrls.add(url);
      }
      await ref
          .read(reviewsRepositoryProvider)
          .addReview(
            target: widget.target,
            rating: _rating,
            comment: _commentController.text.trim(),
            images: imageUrls,
          );
      if (!mounted) return;
      setState(() {
        _showForm = false;
        _rating = 0;
        _commentController.clear();
        _pickedImages.clear();
      });
      ref.invalidate(reviewsProvider(widget.target));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review posted!')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit your review.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(reviewsProvider(widget.target));

    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews · ${widget.title}'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? LucideIcons.x : LucideIcons.plus),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showForm) _buildForm(),
            Expanded(
              child: reviewsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Could not load reviews.',
                    style: AppTheme.poppins(color: AppColors.error),
                  ),
                ),
                data: (reviews) => reviews.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No reviews yet. Be the first to share your experience.',
                            textAlign: TextAlign.center,
                            style: AppTheme.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: reviews.length,
                        separatorBuilder: (_, _) => const Divider(height: 32),
                        itemBuilder: (context, index) =>
                            _ReviewTile(review: reviews[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your rating', style: AppTheme.fredoka(fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: AppColors.primary,
                  size: 32,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share details of your experience...',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._pickedImages.map(
                (image) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    image.bytes,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (_pickedImages.length < 3)
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(LucideIcons.camera, size: 18),
                  label: const Text('Add photo'),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                  : const Text('Post Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                review.author.displayName[0].toUpperCase(),
                style: AppTheme.fredoka(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.author.displayName,
                    style: AppTheme.fredoka(fontSize: 14),
                  ),
                  Text(
                    DateFormat.yMMMd().format(review.createdAt),
                    style: AppTheme.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(review.comment, style: AppTheme.poppins()),
        if (review.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: review.images[index],
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
