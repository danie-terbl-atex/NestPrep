import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../shared/failure/app_failure.dart';
import '../model/compressed_photo.dart';

/// Turns whatever the camera or gallery handed over into a JPEG the rules
/// keep (home-care ADR-0003).
abstract interface class PhotoCompressor {
  Future<CompressedPhoto> compress(Uint8List original);
}

/// Scales to a 1600 px long edge and re-encodes at JPEG quality 80, in a
/// background isolate so the screen does not stall on a 12-megapixel photo.
final class JpegPhotoCompressor implements PhotoCompressor {
  const JpegPhotoCompressor();

  @override
  Future<CompressedPhoto> compress(Uint8List original) =>
      Isolate.run(() => compressNow(original));

  /// The same, on this isolate — what the background isolate runs, and what
  /// a test calls directly.
  static CompressedPhoto compressNow(Uint8List original) {
    final decoded = _decode(original);
    if (decoded == null) {
      throw const HomeCareFailure(HomeCareProblem.photoUnreadable);
    }
    // A phone stores "which way up" as a tag rather than turning the pixels;
    // the tag does not survive the re-encode, so the turn is made now.
    final upright = img.bakeOrientation(decoded);
    final longest = math.max(upright.width, upright.height);
    final scaled = longest <= CompressedPhoto.longEdge
        ? upright
        : upright.width >= upright.height
        ? img.copyResize(upright, width: CompressedPhoto.longEdge)
        : img.copyResize(upright, height: CompressedPhoto.longEdge);
    final photo = CompressedPhoto(
      bytes: img.encodeJpg(scaled, quality: CompressedPhoto.quality),
      width: scaled.width,
      height: scaled.height,
    );
    if (!photo.fitsTheRules) {
      throw const HomeCareFailure(HomeCareProblem.photoTooLarge);
    }
    return photo;
  }

  /// The decoder tries each format in turn, and some of them throw on bytes
  /// that are not theirs rather than saying no. Any of those is the same
  /// answer: this is not a picture the app can read.
  static img.Image? _decode(Uint8List original) {
    try {
      return img.decodeImage(original);
    } on Exception {
      return null;
    } on RangeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}
