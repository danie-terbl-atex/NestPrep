import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'recipe_photo_picker.dart';

final class DeviceRecipePhotoPicker implements RecipePhotoPicker {
  DeviceRecipePhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _largestEdge = 2048.0;

  @override
  Future<List<Uint8List>> pick(
    RecipePhotoOrigin origin, {
    required int limit,
  }) async {
    try {
      final files = switch (origin) {
        RecipePhotoOrigin.camera => await _one(ImageSource.camera),
        // `pickMultiImage` refuses a limit below two.
        RecipePhotoOrigin.library when limit < 2 => await _one(
          ImageSource.gallery,
        ),
        RecipePhotoOrigin.library => await _picker.pickMultiImage(
          limit: limit,
          maxWidth: _largestEdge,
          maxHeight: _largestEdge,
          requestFullMetadata: false,
        ),
      };
      return [for (final file in files.take(limit)) await file.readAsBytes()];
    } on PlatformException catch (error) {
      AppLog.failure('recipe photo picker', code: error.code, error: error);
      throw OwnRecipeFailure(switch (error.code) {
        'camera_access_denied' ||
        'photo_access_denied' => OwnRecipeProblem.recipePhotoRefused,
        _ => OwnRecipeProblem.recipePhotoPickerUnavailable,
      });
    }
  }

  Future<List<XFile>> _one(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: _largestEdge,
      maxHeight: _largestEdge,
      requestFullMetadata: false,
    );
    return [?file];
  }
}
