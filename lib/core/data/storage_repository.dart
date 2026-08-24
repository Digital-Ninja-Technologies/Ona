import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';

/// Uploads user photos (review/community post images) to the shared
/// `uploads` Supabase Storage bucket and returns a public URL.
class StorageRepository {
  StorageRepository(this._ref);

  final Ref _ref;

  Future<String> uploadImage(Uint8List bytes, {required String extension}) async {
    final client = _ref.read(supabaseProvider);
    final userId = client.auth.currentUser?.id ?? 'anonymous';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}.$extension';
    final path = '$userId/$fileName';
    await client.storage.from('uploads').uploadBinary(path, bytes);
    return client.storage.from('uploads').getPublicUrl(path);
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref);
});
