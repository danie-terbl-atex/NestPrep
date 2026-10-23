import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../state/recipe_catalogue_controller.dart';
import 'recipe_picture.dart';

/// The small photo beside a meal on the week that was planned from a recipe
/// (recipes ADR-0003 §6), looked up in the catalogue the Meals tab already
/// listens to — by id, so a slot rebuilds only when its own recipe changes.
/// A recipe the catalogue no longer holds keeps the placeholder. Decoration:
/// the meal's name beside it says what it is.
class PlannedRecipeThumb extends StatelessWidget {
  const PlannedRecipeThumb({required this.recipeId, super.key});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final path = context.select<RecipeCatalogueController?, String?>(
      (catalogue) => catalogue?.recipe(recipeId)?.photo?.card,
    );
    return SizedBox.square(
      dimension: NestSize.controlSmall,
      child: NestPhotoFrame(
        radius: NestRadius.sm,
        child: RecipePicture(path: path),
      ),
    );
  }
}
