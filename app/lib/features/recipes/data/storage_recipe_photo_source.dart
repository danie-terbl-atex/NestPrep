import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/log/app_log.dart';
import '../../../shared/photos/kept_photo_files.dart';
import 'recipe_photo_source.dart';

/// `recipes/{recipeId}/…` in Cloud Storage (recipes ADR-0003 §4), kept on the
/// phone by path once read — the same way the lunch photos are — so a
/// catalogue opened offline still has its pictures.
final class StorageRecipePhotoSource implements RecipePhotoSource {
  StorageRecipePhotoSource(this._storage);

  final FirebaseStorage _storage;
  final _kept = KeptPhotoFiles('recipe_photos');
  final _requests = <String, Future<Uint8List?>>{};

  /// A hero is about 1200 px of JPEG; anything far past that is not ours.
  static const _largest = 2 * 1024 * 1024;

  @override
  Future<Uint8List?> photo(String path) =>
      _requests.putIfAbsent(path, () async {
        final bytes = await _fetch(path);
        // A miss is asked again next time rather than remembered as none.
        if (bytes == null) _requests.removeWhere((asked, _) => asked == path);
        return bytes;
      });

  Future<Uint8List?> _fetch(String path) async {
    try {
      return await _kept.read(
        path,
        orFetch: () => _storage.ref(path).getData(_largest),
      );
    } on Exception catch (error) {
      AppLog.failure('recipe photo', code: 'unavailable', error: error);
      return null;
    }
  }
}
