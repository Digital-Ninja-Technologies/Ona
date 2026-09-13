import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/geocoding_repository.dart';
import '../theme/app_colors.dart';
import 'app_loader.dart';

/// The tile server + attribution shared by every map in the app — free,
/// keyless OpenStreetMap tiles. OSM's usage policy requires both a
/// descriptive User-Agent and visible attribution, which [_AttributedMap]
/// provides via [RichAttributionWidget].
const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgent = 'com.digitalninjatechnologies.ona';

/// A small, interactive (pan/zoom) map centered on [query] — a place name
/// or address, geocoded client-side via the device's native geocoder (no
/// API key). Tap it to open the same location full-screen. Renders nothing
/// if [query] can't be geocoded, so it never leaves a broken-looking gap.
class PlaceMapPreview extends ConsumerWidget {
  const PlaceMapPreview({
    super.key,
    required this.query,
    required this.label,
    this.height = 180,
  });

  final String query;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(placeCoordinatesProvider(query));

    return coordinates.when(
      loading: () => SizedBox(
        height: height,
        child: const AppLoaderCenter(padding: EdgeInsets.zero),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (point) {
        if (point == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PlaceMapScreen(point: point, label: label),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: height,
              child: IgnorePointer(
                // The preview is a tap target for the full-screen map, not
                // its own pan/zoom surface — avoids fighting the page's
                // scroll gesture.
                child: _AttributedMap(point: point, label: label),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen, fully interactive version of [PlaceMapPreview] — pinch to
/// zoom, drag to pan — with a "Get Directions" action handed to Google
/// Maps (this app has no routing API of its own).
class PlaceMapScreen extends StatelessWidget {
  const PlaceMapScreen({super.key, required this.point, required this.label});

  final LatLng point;
  final String label;

  Future<void> _openDirections(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${point.latitude},${point.longitude}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open Maps.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: _AttributedMap(point: point, label: label, interactive: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDirections(context),
        icon: const Icon(LucideIcons.navigation),
        label: const Text('Directions'),
      ),
    );
  }
}

class _AttributedMap extends StatelessWidget {
  const _AttributedMap({
    required this.point,
    required this.label,
    this.interactive = false,
  });

  final LatLng point;
  final String label;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 15,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(urlTemplate: _osmTileUrl, userAgentPackageName: _osmUserAgent),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 40,
              height: 40,
              alignment: Alignment.topCenter,
              child: const Icon(
                LucideIcons.mapPin,
                color: AppColors.error,
                size: 36,
              ),
            ),
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
