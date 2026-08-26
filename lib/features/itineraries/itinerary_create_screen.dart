import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/itineraries_repository.dart';
import '../../core/models/itinerary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

const _durations = [1, 3, 5, 7, 10, 14];
const _budgets = [
  ('budget', 'Budget'),
  ('moderate', 'Moderate'),
  ('luxury', 'Luxury'),
];

class ItineraryCreateScreen extends ConsumerStatefulWidget {
  const ItineraryCreateScreen({super.key});

  @override
  ConsumerState<ItineraryCreateScreen> createState() =>
      _ItineraryCreateScreenState();
}

class _ItineraryCreateScreenState extends ConsumerState<ItineraryCreateScreen> {
  String _mode = 'ai';

  // AI mode state
  final _destinationController = TextEditingController();
  int _selectedDuration = 3;
  String _selectedBudget = 'moderate';
  bool _generating = false;
  ItineraryDraft? _draft;

  // Manual mode state
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<List<TextEditingController>> _manualDays = [
    [TextEditingController()],
  ];

  bool _saving = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    for (final day in _manualDays) {
      for (final controller in day) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _generate() async {
    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a destination first.')),
      );
      return;
    }
    setState(() {
      _generating = true;
      _draft = null;
    });
    try {
      final draft = await ref
          .read(itinerariesRepositoryProvider)
          .generateItinerary(
            destination: _destinationController.text.trim(),
            days: _selectedDuration,
            budget: _selectedBudget,
          );
      if (draft.days.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "The AI couldn't put together a day-by-day plan for that "
                'trip. Try a different destination or duration.',
              ),
            ),
          );
        }
      } else {
        setState(() => _draft = draft);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate itinerary. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _saveAiItinerary() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(itinerariesRepositoryProvider)
          .createItinerary(
            title: draft.title,
            description: draft.description,
            destinationName: _destinationController.text.trim(),
            durationDays: _selectedDuration,
            budget: _selectedBudget,
            isAiGenerated: true,
            days: draft.days,
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

  Future<void> _saveManualItinerary() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your itinerary a title.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final days = <ItineraryDay>[];
      for (var i = 0; i < _manualDays.length; i++) {
        final activities = _manualDays[i]
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();
        days.add(ItineraryDay(day: i + 1, activities: activities));
      }
      await ref
          .read(itinerariesRepositoryProvider)
          .createItinerary(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            durationDays: _manualDays.length,
            isAiGenerated: false,
            days: days,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Itinerary')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      icon: LucideIcons.sparkles,
                      label: 'AI Generated',
                      selected: _mode == 'ai',
                      onTap: () => setState(() => _mode = 'ai'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeButton(
                      icon: LucideIcons.pencil,
                      label: 'Build Manually',
                      selected: _mode == 'manual',
                      onTap: () => setState(() => _mode = 'manual'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _mode == 'ai' ? _buildAiMode() : _buildManualMode(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMode() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text('Destination', style: AppTheme.fredoka(fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _destinationController,
          decoration: const InputDecoration(hintText: 'e.g. Kyoto, Japan'),
        ),
        const SizedBox(height: 20),
        Text('Duration', style: AppTheme.fredoka(fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _durations.map((days) {
            return ChoiceChip(
              label: Text(
                days == 14 ? '2 Weeks' : '$days Day${days > 1 ? 's' : ''}',
              ),
              selected: _selectedDuration == days,
              onSelected: (_) => setState(() => _selectedDuration = days),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Budget', style: AppTheme.fredoka(fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _budgets.map((entry) {
            final (value, label) = entry;
            return ChoiceChip(
              label: Text(label),
              selected: _selectedBudget == value,
              onSelected: (_) => setState(() => _selectedBudget = value),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _generating ? null : _generate,
          icon: _generating
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.sparkles),
          label: Text(_generating ? 'Generating...' : 'Generate with AI'),
        ),
        if (_draft != null) ...[
          const SizedBox(height: 24),
          Text(_draft!.title, style: AppTheme.fredoka(fontSize: 18)),
          if (_draft!.description != null) ...[
            const SizedBox(height: 8),
            Text(
              _draft!.description!,
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          ..._draft!.days.map((day) => _DayPreview(day: day)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _saveAiItinerary,
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
        ],
      ],
    );
  }

  Widget _buildManualMode() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text('Title', style: AppTheme.fredoka(fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(hintText: 'My trip to...'),
        ),
        const SizedBox(height: 16),
        Text('Description', style: AppTheme.fredoka(fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Optional notes'),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _manualDays.length; i++) _buildDayEditor(i),
        OutlinedButton.icon(
          onPressed: () =>
              setState(() => _manualDays.add([TextEditingController()])),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add Day'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _saveManualItinerary,
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
      ],
    );
  }

  Widget _buildDayEditor(int dayIndex) {
    final activities = _manualDays[dayIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Day ${dayIndex + 1}',
                  style: AppTheme.fredoka(fontSize: 15),
                ),
              ),
              if (_manualDays.length > 1)
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => setState(() {
                    for (final controller in _manualDays[dayIndex]) {
                      controller.dispose();
                    }
                    _manualDays.removeAt(dayIndex);
                  }),
                ),
            ],
          ),
          for (var i = 0; i < activities.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: activities[i],
                      decoration: InputDecoration(
                        hintText: 'Activity ${i + 1}',
                      ),
                    ),
                  ),
                  if (activities.length > 1)
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () => setState(() {
                        activities[i].dispose();
                        activities.removeAt(i);
                      }),
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => activities.add(TextEditingController())),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add activity'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTheme.poppins(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPreview extends StatelessWidget {
  const _DayPreview({required this.day});

  final ItineraryDay day;

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
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $activity', style: AppTheme.poppins(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
