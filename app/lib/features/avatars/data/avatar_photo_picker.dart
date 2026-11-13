import 'dart:typed_data';

enum AvatarPhotoSource { camera, library }

abstract interface class AvatarPhotoPicker {
  Future<Uint8List?> pick(AvatarPhotoSource source, {bool facingUser = true});
}
