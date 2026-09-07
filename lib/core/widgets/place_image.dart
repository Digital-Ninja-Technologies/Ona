import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/place_image_repository.dart';
import '../theme/app_colors.dart';
import 'image_loading_placeholder.dart';
import 'no_image_placeholder.dart';

/// A place photo that is resilient to the server-attached [imageUrl] being
/// missing or broken: it verifies that URL and, failing that, looks a photo
/// up from Wikipedia via [fallbackQuery] before showing the
/// [NoImagePlaceholder]. See [placePhotoProvider].
///
/// Keep [fallbackQuery] specific: the place name plus its city/locality
/// ("Yoyogi Park, Tokyo") matches far better than the bare name.
class PlaceImage extends ConsumerWidget {
  const PlaceImage({
    super.key,
    required this.imageUrl,
    required this.fallbackQuery,
    this.fit = BoxFit.cover,
    this.background = AppColors.surface,
  });

  final String? imageUrl;
  final String fallbackQuery;
  final BoxFit fit;
  final Color background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(
      placePhotoProvider((primaryUrl: imageUrl, query: fallbackQuery)),
    );
    return photo.when(
      loading: () => ImageLoadingPlaceholder(background: background),
      error: (_, _) => const NoImagePlaceholder(),
      data: (url) => url == null || url.isEmpty
          ? const NoImagePlaceholder()
          : CachedNetworkImage(
              imageUrl: url,
              fit: fit,
              placeholder: (context, url) =>
                  ImageLoadingPlaceholder(background: background),
              errorWidget: (context, url, error) => const NoImagePlaceholder(),
            ),
    );
  }
}
