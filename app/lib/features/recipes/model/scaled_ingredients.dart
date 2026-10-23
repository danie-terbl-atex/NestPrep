import 'package:flutter/foundation.dart';

import '../../meal_planning/model/ingredient_unit.dart';
import 'recipe_amount.dart';
import 'recipe_ingredient.dart';
import 'recipe_scale.dart';

/// One ingredient as the recipe page reads it at the chosen scale: its own
/// words, and its amount scaled and rounded — or none, for a line like
/// "salt, to taste", which never scales (recipes ADR-0003 §5).
@immutable
final class ScaledIngredient {
  const ScaledIngredient({
    required this.line,
    required this.amount,
    this.index = 0,
  });

  final RecipeIngredient line;

  /// Its place in the recipe's own list — what a tick is kept against, so
  /// grouping never moves a tick to another line.
  final int index;
  final RecipeAmount? amount;

  /// The stored unit word, for a unit this build does not know — shown as
  /// written rather than dropped.
  String? get otherUnit => amount?.unit == null ? line.unit : null;
}

/// A recipe's ingredients in their parts ("For the sauce"), in the order the
/// recipe uses them. A recipe without parts is one group with no title.
@immutable
final class IngredientGroup {
  const IngredientGroup({required this.title, required this.lines});

  final String? title;
  final List<ScaledIngredient> lines;
}

/// [lines] at [scale], grouped by their `group` as they first appear —
/// computed once per change of scale, never in a build (`FE-12`).
List<IngredientGroup> scaledIngredientGroups(
  List<RecipeIngredient> lines,
  RecipeScale scale,
) {
  final groups = <String?, List<ScaledIngredient>>{};
  for (final (index, line) in lines.indexed) {
    groups
        .putIfAbsent(line.group, () => [])
        .add(scaleIngredient(line, scale, index: index));
  }
  return [
    for (final MapEntry(:key, :value) in groups.entries)
      IngredientGroup(title: key, lines: value),
  ];
}

ScaledIngredient scaleIngredient(
  RecipeIngredient line,
  RecipeScale scale, {
  int index = 0,
}) => ScaledIngredient(
  line: line,
  index: index,
  amount: switch (line.quantity) {
    final quantity? => RecipeAmount.scaled(
      quantity,
      unit: IngredientUnit.fromCode(line.unit),
      factor: scale.factor,
    ),
    null => null,
  },
);
