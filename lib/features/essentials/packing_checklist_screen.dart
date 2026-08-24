import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class _ChecklistCategory {
  const _ChecklistCategory({required this.title, required this.items});

  final String title;
  final List<String> items;
}

const _categories = [
  _ChecklistCategory(
    title: 'Documents & Money',
    items: [
      'Passport',
      'Visa (if required)',
      'Flight tickets',
      'Hotel confirmations',
      'Travel insurance',
      'Credit/debit cards',
      'Local currency',
      "Driver's license",
    ],
  ),
  _ChecklistCategory(
    title: 'Clothing',
    items: [
      'Underwear',
      'Socks',
      'Shirts/tops',
      'Pants/shorts',
      'Jacket/sweater',
      'Comfortable shoes',
      'Sandals/flip-flops',
      'Swimwear',
    ],
  ),
  _ChecklistCategory(
    title: 'Toiletries',
    items: [
      'Toothbrush & toothpaste',
      'Shampoo & conditioner',
      'Soap/body wash',
      'Deodorant',
      'Sunscreen',
      'Medications',
      'First aid kit',
      'Razor',
    ],
  ),
  _ChecklistCategory(
    title: 'Electronics',
    items: [
      'Phone',
      'Phone charger',
      'Power adapter',
      'Camera',
      'Headphones',
      'Laptop/tablet',
      'Power bank',
    ],
  ),
  _ChecklistCategory(
    title: 'Miscellaneous',
    items: [
      'Sunglasses',
      'Hat/cap',
      'Umbrella',
      'Daypack/backpack',
      'Water bottle',
      'Snacks',
      'Book/entertainment',
      'Luggage locks',
    ],
  ),
];

class PackingChecklistScreen extends StatefulWidget {
  const PackingChecklistScreen({super.key});

  @override
  State<PackingChecklistScreen> createState() => _PackingChecklistScreenState();
}

class _PackingChecklistScreenState extends State<PackingChecklistScreen> {
  final Set<String> _checked = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packing Checklist')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Check off items as you pack them',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            for (final category in _categories)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.title,
                          style: AppTheme.fredoka(fontSize: 16),
                        ),
                        Text(
                          '${category.items.where((item) => _checked.contains('${category.title}:$item')).length}/${category.items.length}',
                          style: AppTheme.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    for (final item in category.items)
                      _ChecklistRow(
                        label: item,
                        checked: _checked.contains('${category.title}:$item'),
                        onChanged: (value) {
                          setState(() {
                            final key = '${category.title}:$item';
                            if (value) {
                              _checked.add(key);
                            } else {
                              _checked.remove(key);
                            }
                          });
                        },
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

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_circle : Icons.circle_outlined,
              color: checked ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style:
                    AppTheme.poppins(
                      color: checked ? AppColors.textSecondary : AppColors.text,
                    ).copyWith(
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
