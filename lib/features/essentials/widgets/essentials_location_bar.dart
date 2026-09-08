import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// The location input row shared by the location-based essentials tools
/// (food guide, SIM cards) — a text field to type a city/country, a submit
/// button, and a "use my location" button. Shows the resolved [location]
/// as the field's text.
class EssentialsLocationBar extends StatefulWidget {
  const EssentialsLocationBar({
    super.key,
    required this.location,
    required this.resolving,
    required this.hintText,
    required this.onSubmitted,
    required this.onUseMyLocation,
  });

  final String? location;
  final bool resolving;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onUseMyLocation;

  @override
  State<EssentialsLocationBar> createState() => _EssentialsLocationBarState();
}

class _EssentialsLocationBarState extends State<EssentialsLocationBar> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.location != null) _controller.text = widget.location!;
  }

  @override
  void didUpdateWidget(EssentialsLocationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when the location is resolved externally
    // (e.g. from geolocation), but don't stomp what the user is typing.
    if (widget.location != null &&
        widget.location != oldWidget.location &&
        widget.location != _controller.text) {
      _controller.text = widget.location!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(LucideIcons.mapPin),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _submit,
              icon: const Icon(LucideIcons.arrowRight),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.resolving ? null : widget.onUseMyLocation,
            icon: widget.resolving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.locateFixed, size: 16),
            label: Text(
              widget.resolving ? 'Finding you...' : 'Use my location',
              style: AppTheme.poppins(fontSize: 13, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
