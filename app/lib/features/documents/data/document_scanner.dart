import 'dart:typed_data';

/// The phone's own document scanner — ML Kit on Android, VisionKit on iOS —
/// which finds the page's edges and crops it (documents ADR-0004).
///
/// Behind an interface because a widget test has no camera, and because
/// backing out of the scanner is a choice the screen says nothing about.
abstract interface class DocumentScanner {
  /// Scans up to [maxPages] sides and returns each as image bytes, or null
  /// when the person backed out. Throws a `DocumentFailure` when the scanner
  /// could not run or the camera was refused.
  Future<List<Uint8List>?> scan({required int maxPages});
}
