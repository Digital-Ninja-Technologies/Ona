import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Resolves a usable photo URL for a place card.
///
/// The `ai-assistant` edge function attaches a Brave Image Search result to
/// each [PlaceSuggestion], but that can be missing (null) or degenerate —
/// Brave's proxy returns a ~1 KB broken-image placeholder when the upstream
/// source fails, which loads "successfully" and renders as a blank tile. So
/// this checks the server URL actually points at a real image and, when it
/// doesn't, falls back to Wikipedia's free, keyless API for a page lead
/// image (most landmarks, parks, museums, and neighbourhoods have one).
///
/// Returns null only when both the server URL and the Wikipedia lookup come
/// up empty — callers then show the no-image placeholder. Results are
/// memoised for the session.
class PlaceImageRepository {
  PlaceImageRepository(this._client);

  final http.Client _client;
  final _resolved = <String, Future<String?>>{};
  final _wikipedia = <String, Future<String?>>{};

  /// [primaryUrl] is the server-attached image (may be null); [query] is the
  /// place name, ideally with its city/locality appended, for the fallback.
  Future<String?> resolve(String? primaryUrl, String query) {
    final key = '${primaryUrl ?? ''}|${query.trim().toLowerCase()}';
    return _resolved.putIfAbsent(key, () => _resolve(primaryUrl, query.trim()));
  }

  Future<String?> _resolve(String? primaryUrl, String query) async {
    if (primaryUrl != null &&
        primaryUrl.isNotEmpty &&
        await _isRealImage(primaryUrl)) {
      return primaryUrl;
    }
    if (query.isEmpty) return null;
    return _wikipedia.putIfAbsent(
      query.toLowerCase(),
      () => _wikipediaImage(query),
    );
  }

  /// True if [url] returns a real raster image and not a tiny broken-image
  /// placeholder. Fetches only the first few KB via a Range request where
  /// the server supports it.
  Future<bool> _isRealImage(String url) async {
    const minBytes = 2048;
    try {
      final res = await _client
          .get(Uri.parse(url), headers: {'range': 'bytes=0-8191'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 && res.statusCode != 206) return false;
      if (!(res.headers['content-type'] ?? '').startsWith('image/')) {
        return false;
      }
      // Prefer the reported total size so we don't read a whole large image
      // just to measure it: "bytes 0-8191/12345" on a 206, or Content-Length
      // on a 200 that ignored the Range request.
      final total =
          int.tryParse(
            (res.headers['content-range'] ?? '').split('/').last,
          ) ??
          int.tryParse(res.headers['content-length'] ?? '');
      if (total != null) return total >= minBytes;
      return res.bodyBytes.length >= minBytes;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _wikipediaImage(String query) async {
    try {
      // generator=search tolerates loose queries ("Golden Gate Bridge, San
      // Francisco") where the REST summary endpoint needs an exact title.
      final uri = Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'generator': 'search',
        'gsrsearch': query,
        'gsrlimit': '1',
        'gsrnamespace': '0',
        'prop': 'pageimages',
        'piprop': 'thumbnail|original',
        'pithumbsize': '800',
        'redirects': '1',
      });
      final res = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final pages =
          (data['query'] as Map<String, dynamic>?)?['pages']
              as Map<String, dynamic>?;
      if (pages == null || pages.isEmpty) return null;

      final page = pages.values.first as Map<String, dynamic>;
      final thumb =
          (page['thumbnail'] as Map<String, dynamic>?)?['source'] as String?;
      if (thumb != null && thumb.isNotEmpty) return thumb;
      final original =
          (page['original'] as Map<String, dynamic>?)?['source'] as String?;
      if (original != null && original.isNotEmpty) return original;
      return null;
    } catch (_) {
      // Network error, timeout, bad JSON — degrade to "no fallback image".
      return null;
    }
  }
}

final placeImageRepositoryProvider = Provider<PlaceImageRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return PlaceImageRepository(client);
});

/// A usable photo URL for a place — the server-attached image if it checks
/// out, else a Wikipedia fallback, else null. Keyed by the server URL plus
/// the fallback query.
final placePhotoProvider =
    FutureProvider.family<String?, ({String? primaryUrl, String query})>((
      ref,
      args,
    ) {
      return ref
          .watch(placeImageRepositoryProvider)
          .resolve(args.primaryUrl, args.query);
    });
