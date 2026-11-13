import 'dart:typed_data';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../../../shared/photos/jpeg_compressor.dart';
import '../../../shared/photos/photo_compressor.dart';
import '../data/storage_avatar_photo_store.dart';

final class CreationReference {
  const CreationReference({
    this.compressor = const JpegCompressor(
      maxBytes: StorageAvatarPhotoStore.referenceMaxBytes,
      unreadable: AvatarFailure(AvatarProblem.photoUnreadable),
      tooLarge: AvatarFailure(AvatarProblem.photoTooLarge),
      maxEdge: longEdge,
      jpegQuality: quality,
    ),
  });

  static const longEdge = 1024;
  static const quality = 85;

  final PhotoCompressor compressor;

  Future<CompressedPhoto> prepare(Uint8List original) =>
      compressor.compress(original);
}
