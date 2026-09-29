import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/log/best_effort.dart';
import 'document_scanner.dart';

/// `cunning_document_scanner`: the platform scanners behind one call
/// (documents ADR-0004). Pages come back as files in the plugin's cache; they
/// are read into memory and the cache is emptied at once, so no ID card stays
/// on the phone's disk (documents ADR-0003).
final class PlatformDocumentScanner implements DocumentScanner {
  const PlatformDocumentScanner();

  @override
  Future<List<Uint8List>?> scan({required int maxPages}) async {
    final List<String>? paths;
    try {
      paths = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        iosScannerOptions: IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.9,
        ),
      );
    } on CunningDocumentScannerException catch (error) {
      AppLog.failure(
        'document scan',
        code: error.code ?? 'unknown',
        error: error,
      );
      throw DocumentFailure(
        error.code == 'permission_denied'
            ? DocumentProblem.cameraRefused
            : DocumentProblem.scanFailed,
      );
    }
    if (paths == null) return null;
    try {
      return [for (final path in paths) await File(path).readAsBytes()];
    } on FileSystemException catch (error) {
      AppLog.failure('document scan', code: 'unreadable-page', error: error);
      throw const DocumentFailure(DocumentProblem.scanFailed);
    } finally {
      // Nothing waits on this; a cache the plugin could not empty is logged
      // and emptied again by the next scan.
      await bestEffort(
        'document scan cache',
        code: 'clean-failed',
        run: CunningDocumentScanner.cleanCache,
      );
    }
  }
}
