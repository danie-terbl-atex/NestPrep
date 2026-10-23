import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe.dart';
import '../model/recipe_shelf.dart';
import 'recipe_card.dart';

/// One curated shelf — *Braai day*, *Something sweet* — as a heading and a
/// row of cards that scrolls sideways past the screen's edge, so it is plain
/// there is more. A shelf holds at most `RecipeShelf.limit`, so the row is
/// built whole; the row is as tall as its tallest card, which keeps a name
/// at 200% text from being clipped (`FE-14`).
class RecipeShelfRow extends StatelessWidget {
  const RecipeShelfRow({required this.shelf, required this.onOpen, super.key});

  final RecipeShelf shelf;
  final ValueChanged<Recipe> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestSectionHeader(title: RecipeCopy.shelf(shelf.kind)),
        const SizedBox(height: NestSpace.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Out to the screen's edges, past the gutter the body keeps.
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, recipe) in shelf.recipes.indexed) ...[
                if (index > 0) const SizedBox(width: NestSpace.md),
                SizedBox(
                  width: NestSize.shelfCardWidth,
                  child: RecipeCard(
                    key: ValueKey(recipe.id),
                    recipe: recipe,
                    onOpen: () => onOpen(recipe),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
