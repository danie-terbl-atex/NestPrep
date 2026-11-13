import 'dart:typed_data';

enum RecipePhotoOrigin { camera, library }

abstract interface class RecipePhotoPicker {
  /// Nothing when the person backed out; never more than [limit].
  Future<List<Uint8List>> pick(RecipePhotoOrigin origin, {required int limit});
}
