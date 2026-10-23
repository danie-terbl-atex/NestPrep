import 'recipe.dart';
import 'recipe_context.dart';
import 'recipe_course.dart';

/// The meal chips over the recipes (recipes ADR-0003 §1): which meal, or
/// which course of any meal, a person is looking for.
enum RecipeMealFilter {
  all,
  breakfast,
  lunch,
  dinner,
  sides,
  desserts,
  lunchBox;

  bool matches(Recipe recipe) => switch (this) {
    all => true,
    breakfast => recipe.contexts.contains(RecipeContext.breakfast),
    lunch => recipe.contexts.contains(RecipeContext.lunch),
    dinner => recipe.contexts.contains(RecipeContext.dinner),
    sides => recipe.isCourse(RecipeCourse.side),
    desserts => recipe.isCourse(RecipeCourse.dessert),
    lunchBox => recipe.contexts.contains(RecipeContext.lunchBox),
  };
}
