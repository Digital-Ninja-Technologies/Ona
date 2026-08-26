import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/place_suggestion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/image_loading_placeholder.dart';

/// Full-detail view for an AI-suggested [PlaceSuggestion] — shown when the
/// user taps a place card/tile on the home screen. Unlike
/// [DestinationDetailScreen] (a database-backed row with its own id), a
/// place suggestion only exists as whatever the AI returned, so it's passed
/// in directly via the route's `extra` rather than looked up by id.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final PlaceSuggestion place;

  Future<void> _openDirections(BuildContext context) async {
    final query = Uri.encodeComponent(
      place.address != null ? '${place.name}, ${place.address}' : place.name,
    );
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    await _launch(context, uri, 'Could not open the maps app.');
  }

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: place.phone);
    await _launch(context, uri, 'Could not open the phone dialer.');
  }

  Future<void> _openWebsite(BuildContext context) async {
    final raw = place.website!;
    final uri = Uri.parse(
      raw.startsWith('http://') || raw.startsWith('https://')
          ? raw
          : 'https://$raw',
    );
    await _launch(context, uri, 'Could not open the website.');
  }

  Future<void> _launch(
    BuildContext context,
    Uri uri,
    String failureMessage,
  ) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: _CircleButton(
              icon: LucideIcons.arrowLeft,
              onTap: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: place.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: place.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ImageLoadingPlaceholder(),
                      errorWidget: (context, url, error) =>
                          Container(color: AppColors.surface),
                    )
                  : Container(color: AppColors.surface),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTheme.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (place.address != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.address!,
                            style: AppTheme.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('About', style: AppTheme.fredoka(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    place.description,
                    style: AppTheme.poppins(color: AppColors.textSecondary),
                  ),
                  if (place.phone != null || place.website != null) ...[
                    const SizedBox(height: 20),
                    Text('Contact', style: AppTheme.fredoka(fontSize: 18)),
                    const SizedBox(height: 8),
                    if (place.phone != null)
                      _ContactRow(
                        icon: LucideIcons.phone,
                        label: place.phone!,
                        onTap: () => _call(context),
                      ),
                    if (place.website != null)
                      _ContactRow(
                        icon: LucideIcons.globe,
                        label: place.website!,
                        onTap: () => _openWebsite(context),
                      ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openDirections(context),
                      icon: const Icon(LucideIcons.navigation),
                      label: const Text('Get Directions'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTheme.poppins(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }
}
