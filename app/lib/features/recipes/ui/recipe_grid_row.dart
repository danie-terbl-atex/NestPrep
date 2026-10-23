import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/recipe.dart';
import 'recipe_card.dart';

/// One row of the recipes grid: [recipes] side by side, as many as the row
/// has [columns], each the same width and the row as tall as its tallest —
/// so a long name never clips and a short one never stretches. A row short
/// of recipes keeps its empty places, so the last card is the same width as
/// the rest.
class RecipeGridRow extends StatelessWidget {
  const RecipeGridRow({
    required this.recipes,
    required this.columns,
    required this.onOpen,
    super.key,
  });

  final List<Recipe> recipes;
  final int columns;
  final ValueChanged<Recipe> onOpen;

  /// Two to a row, or one when the text is so large two names would each
  /// break a word per line (`FE-14`).
  static int columnsFor(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 1 : 2;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < columns; index++) ...[
          if (index > 0) const SizedBox(width: NestSpace.lg),
          Expanded(
            child: index < recipes.length
                ? RecipeCard(
                    key: ValueKey(recipes[index].id),
                    recipe: recipes[index],
                    onOpen: () => onOpen(recipes[index]),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
