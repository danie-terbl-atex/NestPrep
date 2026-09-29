import 'dart:typed_data';

import 'job_photo.dart';

/// A photo ready to store: JPEG bytes no larger than the rules keep, and the
/// size in pixels the job records beside it (home-care ADR-0003).
final class CompressedPhoto {
  const CompressedPhoto({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// The most the rules let one photo be.
  static const maxBytes = 5 * 1024 * 1024;

  /// The longest edge a photo is scaled down to, and its JPEG quality.
  static const longEdge = 1600;
  static const quality = 80;

  static const contentType = 'image/jpeg';

  bool get fitsTheRules => bytes.length <= maxBytes;

  JobPhoto named(String photoId) =>
      JobPhoto(photoId: photoId, width: width, height: height);
}
