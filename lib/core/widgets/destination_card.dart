import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/destination.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'no_image_placeholder.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({
    super.key,
    required this.destination,
    this.width = 200,
    this.onTap,
  });

  final Destination destination;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: destination.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: destination.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: AppColors.surface),
                              errorWidget: (context, url, error) =>
                                  const NoImagePlaceholder(),
                            )
                          : const NoImagePlaceholder(),
                    ),
                    if (destination.rating != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 12,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                destination.rating!.toStringAsFixed(1),
                                style: AppTheme.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              destination.name,
              style: AppTheme.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              destination.country,
              style: AppTheme.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (destination.rating == null || destination.priceRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (destination.rating == null) ...[
                      const Icon(
                        LucideIcons.star,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text('—', style: AppTheme.poppins(fontSize: 12)),
                      if (destination.priceRange != null)
                        const SizedBox(width: 8),
                    ],
                    if (destination.priceRange != null)
                      Text(
                        destination.priceRange!,
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
