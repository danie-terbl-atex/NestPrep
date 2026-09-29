import 'dart:typed_data';

import '../../../shared/failure/app_failure.dart';
import '../data/document_scanner.dart';
import '../data/scan_composer.dart';
import '../model/document_limits.dart';
import '../model/picked_document.dart';

/// A scan from the camera to a file ready to upload, for the household's
/// folders and the vaults alike (documents ADR-0004): at most the two sides of
/// a card, composed into one compressed PDF, and held to the same limits
/// `storage.rules` enforces before anybody waits on an upload.
final class ScanIntake {
  const ScanIntake({required this._scanner, required this._composer});

  /// Front and back. A card has two sides; a longer paper is a PDF somebody
  /// already has, and is picked from files instead.
  static const maxSides = 2;

  final DocumentScanner _scanner;
  final ScanComposer _composer;

  /// The sides somebody scanned, or null when they backed out.
  Future<List<Uint8List>?> capture() => _scanner.scan(maxPages: maxSides);

  /// The sides as one PDF called [name], ready for the upload runner.
  Future<PickedDocument> compose(
    List<Uint8List> pages, {
    required String name,
  }) async {
    final bytes = await _composer.compose(pages);
    final file = PickedDocument(
      name: name,
      contentType: 'application/pdf',
      bytes: bytes,
    );
    final problem = DocumentLimits.problemWith(
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
    );
    if (problem != null) throw DocumentFailure(problem);
    return file;
  }
}
