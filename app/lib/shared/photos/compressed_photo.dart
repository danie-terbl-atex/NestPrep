import 'dart:typed_data';

/// A photo ready to store: JPEG bytes, upright, no longer than
/// `JpegCompressor.longEdge` on either side, carrying no metadata — and its
/// size in pixels, which a screen needs to lay it out before it loads.
final class CompressedPhoto {
  const CompressedPhoto({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// What every compressed photo is, and the only type a photo rule keeps.
  static const contentType = 'image/jpeg';
}
