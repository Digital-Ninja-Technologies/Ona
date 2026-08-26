import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/ai_assistant_repository.dart';
import '../../core/data/destinations_repository.dart';
import '../../core/data/location_repository.dart';
import '../../core/data/nearby_destinations_cache.dart';
import '../../core/models/place_suggestion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/destination_card.dart';
import '../../core/widgets/error_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _locationController = TextEditingController();

  // Non-null once the user submits a manually-typed (or geolocated) place —
  // switches "Local Experiences" from the database list to AI-generated
  // suggestions for that location instead.
  String? _customLocation;
  bool _resolvingLocation = false;

  // "Popular Destinations" driven by the device's actual geolocation only
  // (never by a manual Local Experiences search — see _useMyLocation vs
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
      ref.read(selectedExperienceDestinationProvider.notifier).state = null;
      setState(() {
        _customLocation = name;
        _geoLocation = name;
        _locationController.text = name;
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
    ref.read(selectedExperienceDestinationProvider.notifier).state = null;
    setState(() => _customLocation = text);
  }

  void _clearCustomLocation() {
    setState(() {
      _customLocation = null;
      _locationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinations = ref.watch(popularDestinationsProvider);
    final experiences = ref.watch(popularExperiencesProvider);
    final selectedDestinationId = ref.watch(
      selectedExperienceDestinationProvider,
    );
    final customLocation = _customLocation;
    final nearbyDestinations = _nearbyDestinations;

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
            ref.invalidate(popularExperiencesProvider);
            final location = customLocation;
            if (location != null) {
              ref.invalidate(placesForLocationProvider(location));
            }
            final geoLocation = _geoLocation;
            if (geoLocation != null) {
              await _loadNearbyDestinations(geoLocation);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/brand/ona-logo.png',
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/tabs/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.search,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Search destinations',
                        style: AppTheme.poppins(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    _geoLocation == null
                        ? 'Popular Destinations'
                        : 'Popular Near $_geoLocation',
                    style: AppTheme.fredoka(fontSize: 18),
                  ),
                  const Spacer(),
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
                height: nearbyDestinations != null ? 130 : 230,
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
                                return GestureDetector(
                                  onTap: () {
                                    ref
                                            .read(
                                              selectedExperienceDestinationProvider
                                                  .notifier,
                                            )
                                            .state =
                                        null;
                                    setState(() => _customLocation = place.name);
                                  },
                                  child: Container(
                                    width: 200,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          style: AppTheme.fredoka(
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Expanded(
                                          child: Text(
                                            place.description,
                                            style: AppTheme.poppins(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                onRetry: () => ref.invalidate(
                                  popularDestinationsProvider,
                                ),
                              ),
                            )),
              ),
              const SizedBox(height: 24),
              Text(
                customLocation == null
                    ? 'Local Experiences'
                    : 'Places to Visit in $customLocation',
                style: AppTheme.fredoka(fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (customLocation == null)
                destinations.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length + 1,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final id = index == 0
                                  ? null
                                  : items[index - 1].id;
                              final label = index == 0
                                  ? 'All'
                                  : items[index - 1].name;
                              final selected = selectedDestinationId == id;
                              return ChoiceChip(
                                label: Text(label),
                                selected: selected,
                                onSelected: (_) => ref
                                    .read(
                                      selectedExperienceDestinationProvider
                                          .notifier,
                                    )
                                    .state = id,
                                labelStyle: AppTheme.poppins(
                                  fontSize: 13,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.text,
                                ),
                                backgroundColor: AppColors.surface,
                                selectedColor: AppColors.primary,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              );
                            },
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
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
              const SizedBox(height: 16),
              if (customLocation == null)
                experiences.when(
                  data: (items) => items.isEmpty
                      ? Text(
                          selectedDestinationId == null
                              ? 'No experiences yet'
                              : 'No experiences here yet',
                          style: AppTheme.poppins(
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Column(
                          children: items
                              .map(
                                (experience) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => context.push(
                                      '/experience/${experience.id}',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  experience.title,
                                                  style: AppTheme.fredoka(
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$${experience.price.toStringAsFixed(0)}',
                                                  style: AppTheme.poppins(
                                                    color: AppColors.primary,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorView(
                    message: 'Could not load experiences',
                    onRetry: () => ref.invalidate(popularExperiencesProvider),
                  ),
                )
              else
                ref
                    .watch(placesForLocationProvider(customLocation))
                    .when(
                      data: (items) => items.isEmpty
                          ? Text(
                              "Couldn't find suggestions for "
                              '"$customLocation". Try a different spelling '
                              'or a nearby city.',
                              style: AppTheme.poppins(
                                color: AppColors.textSecondary,
                              ),
                            )
                          : Column(
                              children: items
                                  .map(
                                    (place) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place.name,
                                              style: AppTheme.fredoka(
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              place.description,
                                              style: AppTheme.poppins(
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => ErrorView(
                        message: 'Could not find places for "$customLocation"',
                        onRetry: () => ref.invalidate(
                          placesForLocationProvider(customLocation),
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
