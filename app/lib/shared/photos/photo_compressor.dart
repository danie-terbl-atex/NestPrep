import 'dart:typed_data';

import 'compressed_photo.dart';

/// The seam a feature compresses photos through, so a test can hand it a
/// photo without decoding one. `JpegCompressor` is the one real kind.
abstract interface class PhotoCompressor {
  /// The photo ready to store; the feature's `AppFailure` when it cannot be.
  Future<CompressedPhoto> compress(Uint8List original);
}
