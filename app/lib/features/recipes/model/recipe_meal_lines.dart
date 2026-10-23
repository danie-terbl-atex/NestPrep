import '../../meal_planning/model/meal_ingredient.dart';
import 'recipe.dart';
import 'recipe_scale.dart';
import 'scaled_ingredients.dart';

/// What a recipe's household meal carries (recipes ADR-0003 §6): its lines
/// scaled to the people it is planned for, at most the meal's
/// [MealIngredient.lineLimit], in the meal plan's own units so the grocery
/// list reads them without a translation table (§3).
///
/// A line with no amount stays a bare name; a line in a unit this build does
/// not know keeps its name and loses the amount rather than claiming a count
/// it never was.
List<MealIngredient> recipeMealLines(Recipe recipe, RecipeScale scale) => [
  for (final line in recipe.ingredients.take(MealIngredient.lineLimit))
    _mealLine(scaleIngredient(line, scale)),
];

MealIngredient _mealLine(ScaledIngredient scaled) {
  final name = scaled.line.name;
  final amount = scaled.otherUnit == null ? scaled.amount : null;
  return MealIngredient.typed(
    name: name.length > MealIngredient.nameLimit
        ? name.substring(0, MealIngredient.nameLimit)
        : name,
    amount: amount?.value,
    unit: amount?.unit,
  );
}
