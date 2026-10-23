import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/scaled_ingredients.dart';
import 'recipe_ingredient_row.dart';

/// A recipe's ingredients at the chosen scale, in their parts — each part
/// under its own small heading ("For the sauce"), a recipe without parts as
/// one list. Ticks belong to the page; this shows them and reports a tap.
class RecipeIngredientList extends StatelessWidget {
  const RecipeIngredientList({
    required this.groups,
    required this.isTicked,
    required this.onToggle,
    super.key,
  });

  final List<IngredientGroup> groups;
  final bool Function(int index) isTicked;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (number, group) in groups.indexed) ...[
          if (group.title case final title?)
            Padding(
              padding: EdgeInsets.only(
                top: number == 0 ? NestSpace.xs : NestSpace.xl,
                bottom: NestSpace.xs,
              ),
              child: Text(
                title,
                style: nest.text.label.copyWith(
                  color: nest.colors.accentInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          for (final line in group.lines)
            RecipeIngredientRow(
              key: ValueKey('ingredient-${line.index}'),
              ingredient: line,
              isTicked: isTicked(line.index),
              onToggle: () => onToggle(line.index),
            ),
        ],
      ],
    );
  }
}
