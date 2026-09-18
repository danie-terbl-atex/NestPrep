import 'dart:typed_data';

/// A file somebody chose off their device, before anything has been stored.
///
/// It carries the bytes because that is what both the size check and the upload
/// need, and reading a 20 MiB file twice to answer two questions is worse than
/// holding it once.
class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.contentType,
    required this.bytes,
  });

  /// What the file was called on the device, which is the name offered for the
  /// document unless somebody types a better one.
  final String name;
  final String contentType;
  final Uint8List bytes;

  int get sizeBytes => bytes.length;
}
