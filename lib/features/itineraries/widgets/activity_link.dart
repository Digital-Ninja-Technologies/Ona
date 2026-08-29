import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/data/ai_assistant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// One itinerary activity, rendered as a tappable row that resolves the
/// activity to a real place (via the AI assistant's single-place lookup)
/// and opens it on the place detail screen — used in both the AI itinerary
/// preview and a saved itinerary's detail view.
class ActivityLink extends ConsumerStatefulWidget {
  const ActivityLink({super.key, required this.activity, this.destinationName});

  final String activity;
  final String? destinationName;

  @override
  ConsumerState<ActivityLink> createState() => _ActivityLinkState();
}

class _ActivityLinkState extends ConsumerState<ActivityLink> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final query = widget.destinationName == null
          ? widget.activity
          : '${widget.activity} in ${widget.destinationName}';
      final place = await ref
          .read(aiAssistantRepositoryProvider)
          .lookupPlace(query);
      if (!mounted) return;
      if (place == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find details for this place.'),
          ),
        );
        return;
      }
      context.push('/place-detail', extra: place);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find details for this place.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.activity,
                style: AppTheme.poppins().copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_loading)
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
