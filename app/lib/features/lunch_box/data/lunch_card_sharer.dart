import 'dart:typed_data';

/// How a card or a planner leaves the phone: the platform's share sheet, or
/// its print dialog (lunch-box ADR-0005). Nothing is uploaded or stored.
abstract interface class LunchCardSharer {
  /// Opens the share sheet with one file and the words that go with it.
  /// Throws `LunchFailure` with `shareUnavailable` when the sheet will not
  /// open; closing it without sending is not a failure.
  Future<void> shareFile(LunchSharedFile file);

  /// Opens the system print dialog for a PDF — which also saves one.
  /// Throws `LunchFailure` with `printUnavailable` when this phone cannot.
  Future<void> printPdf({required Uint8List pdf, required String name});
}

/// One file for the share sheet.
final class LunchSharedFile {
  const LunchSharedFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.subject,
    required this.text,
  });

  static const png = 'image/png';
  static const pdf = 'application/pdf';

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final String subject;
  final String text;
}
