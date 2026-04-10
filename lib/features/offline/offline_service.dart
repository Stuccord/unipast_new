import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:unipast/features/offline/cached_item_model.dart';
import 'package:unipast/features/auth/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:unipast/features/browse/storage_service.dart';
import 'package:unipast/core/connectivity_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';

class OfflineService {
  final Isar? _isar; // Now nullable
  final StorageService _storageService;
  final ConnectivityNotifier _connectivity;

  OfflineService(this._isar, this._storageService, this._connectivity);

  Future<void> downloadAndCache({
    required String questionId,
    required String bucket,
    required String path,
    required String title,
    required String userName,
  }) async {
    final isar = _isar;
    if (kIsWeb) {
      return;
    }

    if (!_connectivity.isConnected) {
      throw Exception('No internet connection. Please connect to download.');
    }

    // 1. Download raw bytes
    final bytes = await _storageService.downloadFile(bucket, path);

    // 2. Bake watermark into the PDF using Syncfusion
    final document = PdfDocument(inputBytes: bytes);
    
    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final graphics = page.graphics;
      final pageSize = page.size;

      final font = PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
      final text = '$userName\nDownloaded for offline use\n${DateTime.now().toString().substring(0, 16)}';
      
      // Draw watermark in the center of the page
      graphics.save();
      graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
      graphics.rotateTransform(-45);
      
      graphics.drawString(
        text,
        font,
        brush: PdfSolidBrush(PdfColor(100, 100, 100, 40)), // 40 alpha = ~15% opacity
        bounds: const Rect.fromLTWH(-200, -50, 400, 100),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle,
        ),
      );
      
      graphics.restore();
    }

    final watermarkedBytes = await document.save();
    document.dispose();

    // 3. Save to app-private directory
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/questions/$questionId.pdf');
    await file.create(recursive: true);
    await file.writeAsBytes(watermarkedBytes);

    // 4. Store metadata with 180-day expiry
    final cached = CachedQuestion()
      ..questionId = questionId
      ..title = title
      ..filePath = file.path
      ..downloadedAt = DateTime.now()
      ..expiresAt = DateTime.now().add(const Duration(days: 180));

    await isar!.writeTxn(() async {
      await isar.cachedQuestions.put(cached);
    });
  }

  Future<List<CachedQuestion>> getAllCached() async {
    final isar = _isar;
    if (isar == null) return [];
    return await isar.cachedQuestions.where().findAll();
  }

  Future<void> clearExpired() async {
    final isar = _isar;
    if (isar == null) return;

    final now = DateTime.now();
    await isar.writeTxn(() async {
      final expired =
          await isar.cachedQuestions.filter().expiresAtLessThan(now).findAll();
      for (var item in expired) {
        final file = File(item.filePath);
        if (await file.exists()) await file.delete();
        await isar.cachedQuestions.delete(item.id);
      }
    });
  }
}

final isarProvider = FutureProvider<Isar?>((ref) async {
  final schemas = [
    CachedQuestionSchema,
    UserProfileSchema,
  ];

  if (kIsWeb) {
    return null;
  }

  try {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      schemas,
      directory: dir.path,
    );
  } catch (e) {
    // Isar initialization error
    return null;
  }
});

final offlineServiceProvider = Provider<OfflineService?>((ref) {
  final isarAsync = ref.watch(isarProvider);
  final storage = ref.watch(storageServiceProvider);
  final connectivity = ref.watch(connectivityProvider.notifier);

  return isarAsync.when(
    data: (isar) => OfflineService(isar, storage, connectivity),
    loading: () => null,
    error: (e, stack) {
      debugPrint('❌ offlineServiceProvider error: $e');
      return OfflineService(null, storage, connectivity);
    },
  );
});

final cachedQuestionsProvider =
    FutureProvider<List<CachedQuestion>>((ref) async {
  final service = ref.watch(offlineServiceProvider);
  if (service == null) return [];
  return service.getAllCached();
});
