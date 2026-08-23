import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/destination.dart';
import '../models/experience.dart';

class DestinationsRepository {
  DestinationsRepository(this._ref);

  final Ref _ref;

  Future<List<Destination>> fetchDestinations({
    String? search,
    int limit = 20,
  }) async {
    final client = _ref.read(supabaseProvider);
    var query = client.from('destinations').select();
    if (search != null && search.trim().isNotEmpty) {
      query = query.or('name.ilike.%$search%,country.ilike.%$search%');
    }
    final response = await query.order('rating', ascending: false).limit(limit);
    return (response as List)
        .map((row) => Destination.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Experience>> fetchExperiences({int limit = 10}) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('experiences')
        .select()
        .order('rating', ascending: false)
        .limit(limit);
    return (response as List)
        .map((row) => Experience.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

final destinationsRepositoryProvider = Provider<DestinationsRepository>((ref) {
  return DestinationsRepository(ref);
});

final popularDestinationsProvider = FutureProvider<List<Destination>>((ref) {
  return ref.watch(destinationsRepositoryProvider).fetchDestinations(limit: 10);
});

final popularExperiencesProvider = FutureProvider<List<Experience>>((ref) {
  return ref.watch(destinationsRepositoryProvider).fetchExperiences(limit: 5);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Destination>>((
  ref,
) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Future.value(const []);
  return ref
      .watch(destinationsRepositoryProvider)
      .fetchDestinations(search: query, limit: 50);
});
