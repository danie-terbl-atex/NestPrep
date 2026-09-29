import 'dart:typed_data';

/// Where a photo comes from.
enum PhotoOrigin { camera, gallery }

/// Takes or chooses one photo. Null when the person backed out, which is a
/// choice and not a failure; a refused camera is a `HomeCareFailure`.
abstract interface class PhotoSource {
  Future<Uint8List?> pick(PhotoOrigin origin);
}
