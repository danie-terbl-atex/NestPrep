import 'package:flutter/foundation.dart';

import 'recipe.dart';
import 'recipe_context.dart';
import 'recipe_course.dart';
import 'recipe_tag.dart';

/// The curated rows the recipes open on, each a question a family asks of a
/// week: what is good for us tonight, what to make on Sunday, for a braai, on
/// a busy night, for pudding.
enum RecipeShelfKind {
  healthyWeeknights,
  sundayClassics,
  braaiDay,
  quickWeeknights,
  somethingSweet;

  bool matches(Recipe recipe) => switch (this) {
    healthyWeeknights =>
      recipe.tags.contains(RecipeTag.healthy) &&
          recipe.courseIn(RecipeContext.dinner) == RecipeCourse.main,
    sundayClassics =>
      recipe.courseIn(RecipeContext.dinner) == RecipeCourse.main &&
          recipe.tags.any(
            const {
              RecipeTag.traditional,
              RecipeTag.comfort,
              RecipeTag.festive,
            }.contains,
          ),
    braaiDay => recipe.tags.contains(RecipeTag.braai),
    quickWeeknights =>
      recipe.tags.contains(RecipeTag.quick) &&
          recipe.contexts.contains(RecipeContext.dinner),
    somethingSweet =>
      recipe.isCourse(RecipeCourse.dessert) ||
          recipe.tags.contains(RecipeTag.baking),
  };
}

/// One shelf with what is on it, at most [RecipeShelf.limit].
@immutable
final class RecipeShelf {
  const RecipeShelf({required this.kind, required this.recipes});

  /// Enough to scroll through, few enough that the grid below is still the
  /// place to browse everything.
  static const limit = 10;

  final RecipeShelfKind kind;
  final List<Recipe> recipes;
}
