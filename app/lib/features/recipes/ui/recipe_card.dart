import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe.dart';
import 'recipe_meta_line.dart';
import 'recipe_picture.dart';

/// A recipe opened from the card whose photo carries [heroTag].
typedef RecipeOpened = void Function(Recipe recipe, String heroTag);

/// One recipe to browse: its photo with the brand's round corner, its name
/// in the heading face, and how long and for how many. The whole card is one
/// button to a screen reader, read as one line (`FE-13`); it settles under
/// the finger and reports the tap — where it goes is the screen's
/// (`FE-17`), with the tag its photo flies into the recipe's page by.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    required this.recipe,
    required this.place,
    required this.onOpen,
    super.key,
  });

  final Recipe recipe;

  /// Where on the list this card sits — a shelf, or the full list.
  final String place;
  final RecipeOpened onOpen;

  /// One tag per [place] a recipe's card is shown, since tonight's dinner
  /// can also sit on a shelf and in the list.
  static String heroTagFor(String place, String recipeId) =>
      'recipe/$place/$recipeId';

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final heroTag = heroTagFor(place, recipe.id);
    void open() => onOpen(recipe, heroTag);
    return Semantics(
      button: true,
      label: RecipeCopy.cardLabel(
        name: recipe.name,
        minutes: recipe.totalMinutes,
        servings: recipe.servings,
      ),
      excludeSemantics: true,
      onTap: open,
      child: NestPressable(
        child: GestureDetector(
          onTap: open,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: NestPhotoFrame(
                  heroTag: heroTag,
                  radius: NestRadius.xl,
                  child: RecipePicture(path: recipe.photo?.card),
                ),
              ),
              const SizedBox(height: NestSpace.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: NestSpace.xxs),
                child: Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: nest.text.cardTitle,
                ),
              ),
              const SizedBox(height: NestSpace.xxs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: NestSpace.xxs),
                child: RecipeMetaLine(
                  minutes: recipe.totalMinutes,
                  servings: recipe.servings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
