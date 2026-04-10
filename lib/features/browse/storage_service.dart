import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/core/supabase_config.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});

class StorageService {
  final SupabaseClient _client;
  StorageService(this._client);

  /// Generates a signed URL for a file in a private bucket.
  /// Default expiry is 1 hour (3600 seconds).
  Future<String> getSignedUrl(String bucket, String path,
      {int expiresIn = 3600}) async {
    try {
      final String signedUrl =
          await _client.storage.from(bucket).createSignedUrl(
                path,
                expiresIn,
              );
      return signedUrl;
    } catch (e) {
      throw Exception('Failed to generate signed URL: $e');
    }
  }

  /// Downloads a file as bytes.
  Future<List<int>> downloadFile(String bucket, String path) async {
    try {
      final List<int> bytes = await _client.storage.from(bucket).download(path);
      return bytes;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }
}
