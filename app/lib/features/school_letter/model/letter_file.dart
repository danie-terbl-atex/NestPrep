import 'dart:typed_data';

/// The kinds of file a school letter may be — the server's `LETTER_TYPES`
/// (calendar ADR-0005).
enum LetterKind {
  jpeg('image/jpeg'),
  png('image/png'),
  pdf('application/pdf');

  const LetterKind(this.mimeType);

  final String mimeType;
}

/// A letter on its way to be read: its bytes and what they are. It lives in
/// memory for the one request and is never saved anywhere.
final class LetterFile {
  const LetterFile({required this.bytes, required this.kind});

  final Uint8List bytes;
  final LetterKind kind;

  /// The server's `MAX_LETTER_BYTES`; checked here too so a file that will be
  /// refused is not sent first.
  static const maxBytes = 4 * 1024 * 1024;

  bool get isTooLarge => bytes.length > maxBytes;
}
