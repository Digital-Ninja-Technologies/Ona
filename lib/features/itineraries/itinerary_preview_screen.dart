import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/itineraries_repository.dart';
import '../../core/models/itinerary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/activity_link.dart';

/// Shows an AI-generated itinerary draft on its own screen (reached by
/// pushing from [ItineraryCreateScreen]) so the create form isn't left
/// scrolled halfway through a long day-by-day plan. Pops with `true` on a
/// successful save, which the create screen bubbles up to the itineraries
/// list the same way it always has.
class ItineraryPreviewScreen extends ConsumerStatefulWidget {
  const ItineraryPreviewScreen({
    super.key,
    required this.draft,
    required this.destinationName,
    required this.durationDays,
    required this.budget,
  });

  final ItineraryDraft draft;
  final String destinationName;
  final int durationDays;
  final String budget;

  @override
  ConsumerState<ItineraryPreviewScreen> createState() =>
      _ItineraryPreviewScreenState();
}

class _ItineraryPreviewScreenState
    extends ConsumerState<ItineraryPreviewScreen> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(itinerariesRepositoryProvider)
          .createItinerary(
            title: widget.draft.title,
            description: widget.draft.description,
            destinationName: widget.destinationName,
            durationDays: widget.durationDays,
            budget: widget.budget,
            isAiGenerated: true,
            days: widget.draft.days,
          );
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your itinerary.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Itinerary')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(draft.title, style: AppTheme.fredoka(fontSize: 22)),
            if (draft.description != null) ...[
              const SizedBox(height: 8),
              Text(
                draft.description!,
                style: AppTheme.poppins(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            ...draft.days.map(
              (day) => _DayPreview(
                day: day,
                destinationName: widget.destinationName,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Itinerary'),
          ),
        ),
      ),
    );
  }
}

class _DayPreview extends StatelessWidget {
  const _DayPreview({required this.day, this.destinationName});

  final ItineraryDay day;
  final String? destinationName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day ${day.day}', style: AppTheme.fredoka(fontSize: 14)),
          const SizedBox(height: 6),
          ...day.activities.map(
            (activity) => ActivityLink(
              activity: activity,
              destinationName: destinationName,
            ),
          ),
        ],
      ),
    );
  }
}
