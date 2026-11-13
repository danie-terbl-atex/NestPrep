import 'dart:typed_data';

abstract interface class OwnRecipePhotoStore {
  Future<void> upload({
    required String path,
    required String uploaderUid,
    required Uint8List bytes,
  });

  Future<void> remove(String path);
}
