import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe.dart';

/// The numbers a cook plans by, under a recipe's name: prep, cook and total
/// time, the effort it takes and what it serves as written — each a small
/// label over its value, in columns.
class RecipeFacts extends StatelessWidget {
  const RecipeFacts({required this.recipe, super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final difficulty = recipe.difficulty;
    final facts = [
      _Fact(
        label: RecipeCopy.prepLabel,
        value: RecipeCopy.minutes(recipe.prepMinutes),
      ),
      if (recipe.cookMinutes > 0) ...[
        _Fact(
          label: RecipeCopy.cookLabel,
          value: RecipeCopy.minutes(recipe.cookMinutes),
        ),
        _Fact(
          label: RecipeCopy.totalLabel,
          value: RecipeCopy.minutes(recipe.totalMinutes),
        ),
      ],
      if (difficulty != null)
        _Fact(
          label: RecipeCopy.difficultyLabel,
          value: RecipeCopy.difficulty(difficulty),
        ),
      _Fact(label: RecipeCopy.servesLabel, value: '${recipe.servings}'),
    ];
    // Three to a row, in columns, so a second row lines up under the first;
    // two when the text is so large a third would break its words (`FE-14`).
    final columns = MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 2 : 3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - NestSpace.lg * (columns - 1)) / columns;
        return Wrap(
          spacing: NestSpace.lg,
          runSpacing: NestSpace.lg,
          children: [
            for (final fact in facts) SizedBox(width: width, child: fact),
          ],
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestEyebrow(label),
          const SizedBox(height: NestSpace.xxs),
          Text(value, style: nest.text.bodyStrong),
        ],
      ),
    );
  }
}
