import 'package:flutter/material.dart';

import '../data/countries.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Opens a searchable bottom sheet of [kCountries] and resolves to the
/// chosen country name, or null if dismissed. [current] is highlighted.
Future<String?> showCountryPicker(
  BuildContext context, {
  String? current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (context) => _CountryPickerSheet(current: current),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({this.current});

  final String? current;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _query.isEmpty
        ? kCountries
        : kCountries
              .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
              .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search countries...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        'No match for "$_query"',
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: matches.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(
                          matches[index],
                          style: AppTheme.poppins(fontSize: 14),
                        ),
                        selected: matches[index] == widget.current,
                        selectedColor: AppColors.primary,
                        onTap: () => Navigator.of(context).pop(matches[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
