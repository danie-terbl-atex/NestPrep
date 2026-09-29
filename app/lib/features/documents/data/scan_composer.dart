import 'dart:typed_data';

/// Turns the sides of a scan into the one file that is kept (documents
/// ADR-0004): every side compressed, all of them pages of one PDF.
///
/// Behind an interface so a widget test does not spend a second decoding
/// photographs; `PdfScanComposer` is the real one and has its own tests with
/// real image bytes.
abstract interface class ScanComposer {
  /// One PDF holding [pages] in order — front, then back. Throws a
  /// `DocumentFailure` when a page is not an image it can read.
  Future<Uint8List> compose(List<Uint8List> pages);
}
