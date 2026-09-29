import 'dart:typed_data';

/// Draws a PDF's pages as pictures the app can show itself (documents
/// ADR-0004). A vault PDF is never handed to another app — that would need a
/// download URL or a file on disk, and ADR-0003 rules out both.
abstract interface class PdfPageRenderer {
  /// Each page as PNG bytes, in order. Throws a `DocumentFailure` with
  /// `cannotRender` when the bytes are not a PDF it can draw.
  Future<List<Uint8List>> render(Uint8List pdf);
}
