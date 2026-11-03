import '../../photo_frames/model/frame_share_item.dart';
import '../model/recipe.dart';
import '../model/recipe_ingredient.dart';
import '../model/recipe_scale.dart';
import '../model/scaled_ingredients.dart';
import 'scaled_ingredient_text.dart';

FrameShareRecipe recipeFrameShare(Recipe recipe, RecipeScale scale) =>
    FrameShareRecipe(
      recipeId: recipe.id,
      name: recipe.name,
      people: scale.people,
      amounts: frameAmounts(recipe.ingredients, scale),
      cardPhotoPath: recipe.photo?.card,
    );

List<String?> frameAmounts(List<RecipeIngredient> lines, RecipeScale scale) => [
  for (final line in lines)
    switch (scaleIngredient(line, scale)) {
      ScaledIngredient(amount: null) => null,
      final scaled => ScaledIngredientText.of(scaled).amount,
    },
];
