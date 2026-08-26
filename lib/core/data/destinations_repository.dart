import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../models/attraction.dart';
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

  Future<Destination> fetchDestination(String id) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('destinations')
        .select()
        .eq('id', id)
        .single();
    return Destination.fromJson(response);
  }

  Future<List<Attraction>> fetchAttractions(String destinationId) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('attractions')
        .select()
        .eq('destination_id', destinationId)
        .order('rating', ascending: false);
    return (response as List)
        .map((row) => Attraction.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Experience>> fetchExperiences({
    int limit = 10,
    String? destinationId,
  }) async {
    final client = _ref.read(supabaseProvider);
    var query = client.from('experiences').select();
    if (destinationId != null) {
      query = query.eq('destination_id', destinationId);
    }
    final response = await query.order('rating', ascending: false).limit(limit);
    return (response as List)
        .map((row) => Experience.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Experience> fetchExperience(String id) async {
    final client = _ref.read(supabaseProvider);
    final response = await client
        .from('experiences')
        .select()
        .eq('id', id)
        .single();
    return Experience.fromJson(response);
  }
}

final destinationsRepositoryProvider = Provider<DestinationsRepository>((ref) {
  return DestinationsRepository(ref);
});

final popularDestinationsProvider = FutureProvider<List<Destination>>((ref) {
  return ref.watch(destinationsRepositoryProvider).fetchDestinations(limit: 10);
});

/// The destination the user has picked to filter "Local Experiences" on the
/// home screen. Null means "All" (no filter).
final selectedExperienceDestinationProvider = StateProvider<String?>(
  (ref) => null,
);

final popularExperiencesProvider = FutureProvider<List<Experience>>((ref) {
  final destinationId = ref.watch(selectedExperienceDestinationProvider);
  return ref
      .watch(destinationsRepositoryProvider)
      .fetchExperiences(limit: 5, destinationId: destinationId);
});

final destinationDetailProvider = FutureProvider.family<Destination, String>((
  ref,
  id,
) {
  return ref.watch(destinationsRepositoryProvider).fetchDestination(id);
});

final attractionsProvider = FutureProvider.family<List<Attraction>, String>((
  ref,
  destinationId,
) {
  return ref
      .watch(destinationsRepositoryProvider)
      .fetchAttractions(destinationId);
});

final experienceDetailProvider = FutureProvider.family<Experience, String>((
  ref,
  id,
) {
  return ref.watch(destinationsRepositoryProvider).fetchExperience(id);
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
