import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/log/app_log.dart';
import 'export_sharer.dart';

/// The share sheet, through `share_plus` — the same door the invite leaves
/// by (household ADR-0003) — carrying the export as a JSON file (accounts
/// ADR-0006). The file exists only in the share; the app keeps no copy.
final class PlatformExportSharer implements ExportSharer {
  PlatformExportSharer({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  final SharePlus _sharePlus;

  @override
  Future<bool> share({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      await _sharePlus.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: 'application/json', name: fileName),
          ],
          fileNameOverrides: [fileName],
        ),
      );
      return true;
    } on PlatformException catch (error) {
      // The sheet would not open. The screen says so and offers it again —
      // translated, not lost (ENG-10).
      AppLog.failure('export share', code: error.code, error: error);
      return false;
    }
  }
}
