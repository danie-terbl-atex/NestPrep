import 'dart:typed_data';

/// A shopping list photo on its way to be read: a JPEG, shrunk and stripped
/// of its metadata on the phone. It lives in memory for one request.
final class ListPhoto {
  const ListPhoto(this.bytes);

  final Uint8List bytes;

  static const mimeType = 'image/jpeg';

  /// The server's `MAX_LIST_PHOTO_BYTES`.
  static const maxBytes = 4 * 1024 * 1024;

  bool get isTooLarge => bytes.length > maxBytes;
}
