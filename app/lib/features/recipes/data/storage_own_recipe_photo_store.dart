import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/storage_failure_mapper.dart';
import '../../../shared/photos/compressed_photo.dart';
import 'own_recipe_photo_store.dart';

final class StorageOwnRecipePhotoStore implements OwnRecipePhotoStore {
  const StorageOwnRecipePhotoStore(this._storage);

  static const uploaderKey = 'uploadedByUid';

  final FirebaseStorage _storage;

  @override
  Future<void> upload({
    required String path,
    required String uploaderUid,
    required Uint8List bytes,
  }) async {
    try {
      await _storage
          .ref(path)
          .putData(
            bytes,
            SettableMetadata(
              contentType: CompressedPhoto.contentType,
              customMetadata: {uploaderKey: uploaderUid},
            ),
          );
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }
}
