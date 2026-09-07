import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/ai_assistant_repository.dart';
import '../../core/data/destinations_repository.dart';
import '../../core/data/location_repository.dart';
import '../../core/data/nearby_destinations_cache.dart';
import '../../core/data/notifications_repository.dart';
import '../../core/models/place_category.dart';
import '../../core/models/place_suggestion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/destination_card.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/place_image.dart';
import '../auth/auth_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _locationController = TextEditingController();

  // Non-null once the user submits a manually-typed (or geolocated) place —
  // switches the "explore" section from the database list to AI-generated
  // suggestions for that location instead.
  String? _customLocation;
  bool _resolvingLocation = false;

  // What the user is looking for in _customLocation — attractions, hotels,
  // restaurants, etc. Reset to the default whenever _customLocation changes.
  PlaceCategory _placeCategory = PlaceCategory.initial;

  // Extra AI-generated places for _customLocation + _placeCategory, appended
  // after the initial placesForLocationProvider batch via the "More" button.
  // Reset whenever the location or category changes.
  List<PlaceSuggestion> _morePlaces = [];
  bool _loadingMorePlaces = false;
  String? _loadMorePlacesError;

  // "Popular Destinations" driven by the device's actual geolocation only
  // (never by a manual location search — see _useMyLocation vs
  // _searchCustomLocation). Cached to local storage; refetched only when
  // the resolved location differs from what's cached.
  List<PlaceSuggestion>? _nearbyDestinations;
  bool _loadingNearbyDestinations = false;
  String? _nearbyDestinationsError;
  String? _geoLocation;

  @override
  void initState() {
    super.initState();
    // Show cached nearby destinations instantly (no network) while a fresh
    // geolocation resolves in the background.
    _loadCachedNearbyDestinations();
    // Best-effort: try the device's location once on load so "Local
    // Experiences" and "Popular Destinations" can default to somewhere near
    // the user. Silent on failure (permission not yet granted, services
    // off, etc.) — the user still has the "Near me" chip to retry
    // deliberately, with feedback.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _useMyLocation(silent: true),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedNearbyDestinations() async {
    final cached = await ref
        .read(nearbyDestinationsCacheProvider)
        .readDestinations();
    if (mounted && cached != null && cached.isNotEmpty) {
      setState(() => _nearbyDestinations = cached);
    }
  }

  /// Refreshes "Popular Destinations" for [location] only if it differs
  /// from what's cached — otherwise reuses the cached list without another
  /// AI call, satisfying "refresh on every new location" (and only then).
  Future<void> _loadNearbyDestinations(String location) async {
    final cache = ref.read(nearbyDestinationsCacheProvider);
    final cachedLocation = await cache.readLocation();
    if (cachedLocation == location) {
      final cached = await cache.readDestinations();
      if (cached != null && cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _nearbyDestinations = cached;
            _nearbyDestinationsError = null;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _loadingNearbyDestinations = true;
        _nearbyDestinationsError = null;
      });
    }
    try {
      final fresh = await ref
          .read(aiAssistantRepositoryProvider)
          .fetchNearbyDestinations(location);
      await cache.save(location, fresh);
      if (mounted) setState(() => _nearbyDestinations = fresh);
    } catch (error) {
      if (mounted) setState(() => _nearbyDestinationsError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingNearbyDestinations = false);
    }
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    if (_resolvingLocation) return;
    setState(() => _resolvingLocation = true);
    try {
      final name = await ref
          .read(locationRepositoryProvider)
          .fetchCurrentLocationName();
      if (!mounted) return;
      setState(() {
        _customLocation = name;
        _geoLocation = name;
        _locationController.text = name;
        _placeCategory = PlaceCategory.initial;
        _morePlaces = [];
        _loadMorePlacesError = null;
      });
      unawaited(_loadNearbyDestinations(name));
    } catch (error) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  void _searchCustomLocation() {
    final text = _locationController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _customLocation = text;
      _placeCategory = PlaceCategory.initial;
      _morePlaces = [];
      _loadMorePlacesError = null;
    });
  }

  void _clearCustomLocation() {
    setState(() {
      _customLocation = null;
      _locationController.clear();
      _placeCategory = PlaceCategory.initial;
      _morePlaces = [];
      _loadMorePlacesError = null;
    });
  }

  /// Switches what the location results show — attractions, hotels, etc. The
  /// "More" list is category-specific, so it's cleared on every switch.
  void _selectCategory(PlaceCategory category) {
    if (category == _placeCategory) return;
    setState(() {
      _placeCategory = category;
      _morePlaces = [];
      _loadMorePlacesError = null;
    });
  }

  Future<void> _loadMorePlaces(
    String location,
    PlaceCategory category,
    List<String> alreadyShown,
  ) async {
    setState(() {
      _loadingMorePlaces = true;
      _loadMorePlacesError = null;
    });
    try {
      final more = await ref
          .read(aiAssistantRepositoryProvider)
          .fetchMorePlaces(
            location,
            exclude: alreadyShown,
            category: category,
          );
      if (mounted) setState(() => _morePlaces = [..._morePlaces, ...more]);
    } catch (_) {
      if (mounted) {
        setState(() => _loadMorePlacesError = 'Could not load more places.');
      }
    } finally {
      if (mounted) setState(() => _loadingMorePlaces = false);
    }
  }

  /// The signed-in user's first name, from whichever metadata key their
  /// sign-in method populated (`name` for email/password sign-up — see
  /// AuthController.signUp — or `full_name`/`name` as auto-filled by
  /// Google/Apple). Falls back to a generic greeting if neither is set.
  String _firstNameFrom(User? user) {
    final metadata = user?.userMetadata;
    final raw = (metadata?['name'] ?? metadata?['full_name']) as String?;
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'traveler';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final destinations = ref.watch(popularDestinationsProvider);
    final customLocation = _customLocation;
    final nearbyDestinations = _nearbyDestinations;
    final firstName = _firstNameFrom(ref.watch(currentUserProvider));
    final placesQuery = customLocation == null
        ? null
        : (location: customLocation, category: _placeCategory);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'home-ai-assistant',
        onPressed: () => context.push('/ai-assistant'),
        child: const Icon(LucideIcons.sparkles),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(popularDestinationsProvider);
            if (placesQuery != null) {
              ref.invalidate(placesForLocationProvider(placesQuery));
            }
            final geoLocation = _geoLocation;
            if (geoLocation != null) {
              await _loadNearbyDestinations(geoLocation);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/brand/ona-logo.png',
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  Row(
                    children: [
                      _NotificationsBell(
                        onPressed: () => context.push('/notifications'),
                      ),
                      IconButton(
                        onPressed: () => context.push('/tabs/search'),
                        icon: const Icon(LucideIcons.search),
                        tooltip: 'Search destinations',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to Ọ̀nà (Way Finder)',
                style: AppTheme.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dear $firstName, where are you exploring today?',
                style: AppTheme.poppins(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _geoLocation == null
                          ? 'Popular Destinations'
                          : 'Popular Near $_geoLocation',
                      style: AppTheme.fredoka(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_loadingNearbyDestinations)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: _resolvingLocation ? null : _useMyLocation,
                      child: Icon(
                        LucideIcons.locateFixed,
                        size: 18,
                        color: _resolvingLocation
                            ? AppColors.textSecondary.withValues(alpha: 0.4)
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: nearbyDestinations != null ? 245 : 250,
                child: nearbyDestinations != null
                    ? (nearbyDestinations.isEmpty
                          ? Center(
                              child: Text(
                                'No nearby destinations found',
                                style: AppTheme.poppins(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: nearbyDestinations.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final place = nearbyDestinations[index];
                                return _PlaceCard(
                                  place: place,
                                  fallbackQuery: place.name,
                                  onTap: () => context.push(
                                    '/place-detail',
                                    extra: place,
                                  ),
                                );
                              },
                            ))
                    : (_nearbyDestinationsError != null
                          ? ErrorView(
                              message: 'Could not load nearby destinations',
                              onRetry: () {
                                final geoLocation = _geoLocation;
                                if (geoLocation != null) {
                                  _loadNearbyDestinations(geoLocation);
                                }
                              },
                            )
                          : destinations.when(
                              data: (items) => items.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No destinations yet',
                                        style: AppTheme.poppins(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: items.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) =>
                                          DestinationCard(
                                            destination: items[index],
                                            onTap: () => context.push(
                                              '/destination/${items[index].id}',
                                            ),
                                          ),
                                    ),
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, _) => ErrorView(
                                message: 'Could not load destinations',
                                onRetry: () =>
                                    ref.invalidate(popularDestinationsProvider),
                              ),
                            )),
              ),
              const SizedBox(height: 24),
              Text(
                customLocation == null
                    ? 'Input your location to explore'
                    : _placeCategory.headingFor(customLocation),
                style: AppTheme.fredoka(fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (customLocation != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(LucideIcons.x, size: 14),
                    label: const Text('Clear'),
                    onPressed: _clearCustomLocation,
                    labelStyle: AppTheme.poppins(fontSize: 13),
                    backgroundColor: AppColors.surface,
                    side: BorderSide.none,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'Or type any location...',
                        prefixIcon: Icon(LucideIcons.mapPin),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchCustomLocation(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _searchCustomLocation,
                    icon: const Icon(LucideIcons.arrowRight),
                  ),
                ],
              ),
              if (customLocation != null) ...[
                const SizedBox(height: 12),
                _CategoryChips(
                  selected: _placeCategory,
                  onSelected: _selectCategory,
                ),
              ],
              const SizedBox(height: 16),
              if (placesQuery == null)
                Text(
                  'Search a location above to see places to explore.',
                  style: AppTheme.poppins(color: AppColors.textSecondary),
                )
              else
                ref
                    .watch(placesForLocationProvider(placesQuery))
                    .when(
                      data: (items) => items.isEmpty
                          ? Text(
                              "Couldn't find "
                              '${placesQuery.category.label.toLowerCase()} for '
                              '"${placesQuery.location}". Try a different '
                              'spelling or a nearby city.',
                              style: AppTheme.poppins(
                                color: AppColors.textSecondary,
                              ),
                            )
                          : Column(
                              children: [
                                ...[...items, ..._morePlaces].map(
                                  (place) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _PlaceListTile(
                                      place: place,
                                      fallbackQuery:
                                          '${place.name}, ${placesQuery.location}',
                                      onTap: () => context.push(
                                        '/place-detail',
                                        extra: place,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_loadMorePlacesError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      _loadMorePlacesError!,
                                      style: AppTheme.poppins(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: _loadingMorePlaces
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: CircularProgressIndicator(),
                                        )
                                      : OutlinedButton(
                                          onPressed: () => _loadMorePlaces(
                                            placesQuery.location,
                                            placesQuery.category,
                                            [...items, ..._morePlaces]
                                                .map((p) => p.name)
                                                .toList(),
                                          ),
                                          child: const Text('More'),
                                        ),
                                ),
                              ],
                            ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => ErrorView(
                        message:
                            'Could not find '
                            '${placesQuery.category.label.toLowerCase()} for '
                            '"${placesQuery.location}"',
                        onRetry: () => ref.invalidate(
                          placesForLocationProvider(placesQuery),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A "Popular Near Me" card — Brave-sourced photo on top, name + a
/// three-line description below. Sibling in spirit to [DestinationCard], but
/// for an AI-generated [PlaceSuggestion] rather than a database row.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.onTap,
    required this.fallbackQuery,
  });

  final PlaceSuggestion place;
  final VoidCallback onTap;

  /// Search text for a client-side photo lookup when [place] has no
  /// server-attached image — see [PlaceImage].
  final String fallbackQuery;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: PlaceImage(
                imageUrl: place.imageUrl,
                fallbackQuery: fallbackQuery,
                background: AppColors.border,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTheme.fredoka(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.description,
                    style: AppTheme.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

/// A "Places to Visit" row — thumbnail + name/description, matching the
/// destination detail screen's attraction-card visual pattern.
class _PlaceListTile extends StatelessWidget {
  const _PlaceListTile({
    required this.place,
    required this.onTap,
    required this.fallbackQuery,
  });

  final PlaceSuggestion place;
  final VoidCallback onTap;

  /// Search text for a client-side photo lookup when [place] has no
  /// server-attached image — see [PlaceImage].
  final String fallbackQuery;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: PlaceImage(
                  imageUrl: place.imageUrl,
                  fallbackQuery: fallbackQuery,
                  background: AppColors.border,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: AppTheme.fredoka(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    place.description,
                    style: AppTheme.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

/// Horizontally scrolling filter chips that switch what the location
/// results show — attractions, hotels, restaurants, and so on.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final PlaceCategory selected;
  final ValueChanged<PlaceCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PlaceCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = PlaceCategory.values[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category.label),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            labelStyle: AppTheme.poppins(
              fontSize: 13,
              color: isSelected ? AppColors.cream : AppColors.text,
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            side: BorderSide.none,
          );
        },
      ),
    );
  }
}

/// A bell icon with a small dot badge while there's at least one unread
/// notification.
class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(LucideIcons.bell),
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
