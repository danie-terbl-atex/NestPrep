import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe.dart';
import 'recipe_meta_line.dart';
import 'recipe_picture.dart';

/// One recipe to browse: its photo with the brand's round corner, its name
/// in the heading face, and how long and for how many. The whole card is one
/// button to a screen reader, read as one line (`FE-13`); it settles under
/// the finger and reports the tap — where it goes is the screen's
/// (`FE-17`).
class RecipeCard extends StatelessWidget {
  const RecipeCard({required this.recipe, required this.onOpen, super.key});

  final Recipe recipe;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      button: true,
      label: RecipeCopy.cardLabel(
        name: recipe.name,
        minutes: recipe.totalMinutes,
        servings: recipe.servings,
      ),
      excludeSemantics: true,
      onTap: onOpen,
      child: NestPressable(
        child: GestureDetector(
          onTap: onOpen,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: NestPhotoFrame(
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
