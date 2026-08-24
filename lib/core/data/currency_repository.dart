import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Fetches live exchange rates (base USD) from the free, keyless
/// exchangerate-api.com endpoint — the same one the original app used.
class CurrencyRepository {
  Future<Map<String, double>> fetchRates() async {
    final response = await http.get(
      Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load exchange rates.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = data['rates'] as Map<String, dynamic>;
    return rates.map((code, rate) => MapEntry(code, (rate as num).toDouble()));
  }
}

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  return CurrencyRepository();
});

final exchangeRatesProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.watch(currencyRepositoryProvider).fetchRates();
});
