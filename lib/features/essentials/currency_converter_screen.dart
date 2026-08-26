import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/currency_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import 'currency_data.dart';

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState
    extends ConsumerState<CurrencyConverterScreen> {
  final _amountController = TextEditingController(text: '100');
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? _convert(Map<String, double> rates) {
    final amount = double.tryParse(_amountController.text);
    final fromRate = rates[_fromCurrency];
    final toRate = rates[_toCurrency];
    if (amount == null || fromRate == null || toRate == null) return null;
    final inUsd = amount / fromRate;
    return inUsd * toRate;
  }

  Future<void> _pickCurrency({
    required List<String> codes,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: codes.length,
              itemBuilder: (context, index) {
                final code = codes[index];
                return ListTile(
                  selected: code == current,
                  title: Text('$code — ${currencyNames[code] ?? code}'),
                  onTap: () => Navigator.of(context).pop(code),
                );
              },
            );
          },
        );
      },
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.invalidate(exchangeRatesProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: ratesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message:
                'Could not load exchange rates. Check your connection and '
                'try again.',
            onRetry: () => ref.invalidate(exchangeRatesProvider),
          ),
          data: (rates) {
            final codes = rates.keys.toList()..sort();
            final result = _convert(rates);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 20),
                _CurrencySelector(
                  label: 'From',
                  code: _fromCurrency,
                  onTap: () => _pickCurrency(
                    codes: codes,
                    current: _fromCurrency,
                    onSelected: (code) => setState(() => _fromCurrency = code),
                  ),
                ),
                Center(
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeftRight),
                    onPressed: () => setState(() {
                      final temp = _fromCurrency;
                      _fromCurrency = _toCurrency;
                      _toCurrency = temp;
                    }),
                  ),
                ),
                _CurrencySelector(
                  label: 'To',
                  code: _toCurrency,
                  onTap: () => _pickCurrency(
                    codes: codes,
                    current: _toCurrency,
                    onSelected: (code) => setState(() => _toCurrency = code),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        result == null
                            ? '—'
                            : '${currencySymbols[_toCurrency] ?? ''}${result.toStringAsFixed(2)}',
                        style: AppTheme.fredoka(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 $_fromCurrency = '
                        '${((rates[_toCurrency] ?? 0) / (rates[_fromCurrency] ?? 1)).toStringAsFixed(4)} $_toCurrency',
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: popularCurrencyCodes.map((code) {
                    return ActionChip(
                      label: Text(code),
                      onPressed: () => setState(() => _toCurrency = code),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.label,
    required this.code,
    required this.onTap,
  });

  final String label;
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$code — ${currencyNames[code] ?? code}',
                    style: AppTheme.fredoka(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronDown),
          ],
        ),
      ),
    );
  }
}
