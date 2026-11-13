import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import '../../../shared/failure/app_failure.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../../../shared/photos/jpeg_compressor.dart';
import '../../../shared/photos/photo_compressor.dart';
import '../data/storage_avatar_photo_store.dart';

final class AvatarPhotoCrop {
  const AvatarPhotoCrop({
    this.working = const JpegCompressor(
      maxBytes: workingBytes,
      unreadable: AvatarFailure(AvatarProblem.photoUnreadable),
      tooLarge: AvatarFailure(AvatarProblem.photoTooLarge),
    ),
    this.finished = const JpegCompressor(
      maxBytes: StorageAvatarPhotoStore.maxBytes,
      unreadable: AvatarFailure(AvatarProblem.photoUnreadable),
      tooLarge: AvatarFailure(AvatarProblem.photoTooLarge),
      maxEdge: longEdge,
      jpegQuality: quality,
    ),
  });

  static const longEdge = 512;
  static const quality = 86;
  static const workingBytes = 8 * 1024 * 1024;

  final PhotoCompressor working;
  final PhotoCompressor finished;

  Future<CompressedPhoto> upright(Uint8List original) =>
      working.compress(original);

  Future<CompressedPhoto> crop(Uint8List upright, Rect area) async {
    final square = await Isolate.run(() => cropNow(upright, area));
    if (square == null) {
      throw const AvatarFailure(AvatarProblem.photoUnreadable);
    }
    return finished.compress(square);
  }

  static Uint8List? cropNow(Uint8List upright, Rect area) {
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(upright);
    } on Exception {
      return null;
    }
    if (decoded == null) return null;
    final left = (area.left * decoded.width).round();
    final top = (area.top * decoded.height).round();
    final side = [
      (area.width * decoded.width).round(),
      (area.height * decoded.height).round(),
      decoded.width - left,
      decoded.height - top,
    ].reduce((a, b) => a < b ? a : b);
    if (side < 1) return null;
    final square = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: side,
      height: side,
    );
    return img.encodePng(square, level: 1);
  }
}
