import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/destination.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: destination.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: destination.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.surface),
                        errorWidget: (context, url, error) =>
                            Container(color: AppColors.surface),
                      )
                    : Container(color: AppColors.surface),
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.star, size: 14, color: AppColors.orange),
                const SizedBox(width: 4),
                Text(
                  destination.rating?.toStringAsFixed(1) ?? '—',
                  style: AppTheme.poppins(fontSize: 12),
                ),
                if (destination.priceRange != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    destination.priceRange!,
                    style: AppTheme.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
