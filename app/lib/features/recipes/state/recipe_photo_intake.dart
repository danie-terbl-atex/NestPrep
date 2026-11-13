import 'dart:typed_data';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/photos/jpeg_compressor.dart';
import '../../../shared/photos/photo_compressor.dart';
import '../model/own_recipe_limits.dart';
import '../model/recipe_photo_cuts.dart';

final class RecipePhotoIntake {
  const RecipePhotoIntake({
    this.heroCompressor = _hero,
    this.cardCompressor = _card,
  });

  static const _hero = JpegCompressor(
    maxBytes: OwnRecipeLimits.photoBytes,
    unreadable: OwnRecipeFailure(OwnRecipeProblem.recipePhotoUnreadable),
    tooLarge: OwnRecipeFailure(OwnRecipeProblem.recipePhotoTooLarge),
    maxEdge: 1200,
  );

  static const _card = JpegCompressor(
    maxBytes: OwnRecipeLimits.photoBytes,
    unreadable: OwnRecipeFailure(OwnRecipeProblem.recipePhotoUnreadable),
    tooLarge: OwnRecipeFailure(OwnRecipeProblem.recipePhotoTooLarge),
    maxEdge: 640,
  );

  final PhotoCompressor heroCompressor;
  final PhotoCompressor cardCompressor;

  Future<RecipePhotoCuts> cut(Uint8List original) async {
    final hero = await heroCompressor.compress(original);
    return RecipePhotoCuts(
      hero: hero,
      card: await cardCompressor.compress(hero.bytes),
    );
  }
}
