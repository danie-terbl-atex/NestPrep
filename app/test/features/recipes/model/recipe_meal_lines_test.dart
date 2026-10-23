import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_meal_lines.dart';
import 'package:nestprep/features/recipes/model/recipe_scale.dart';

import '../../../support/recipe_fixtures.dart';

/// What a planned recipe's household meal carries (recipes ADR-0003 §6):
/// its lines at the chosen scale, in the meal plan's own units, never more
/// than a meal may hold.
void main() {
  final bobotie = RecipeFixtures.bobotie;

  test('every line at the scale chosen, in the meal plan’s units', () {
    final lines = recipeMealLines(bobotie, RecipeScale(people: 4, servings: 6));
    final mince = lines.firstWhere((line) => line.name == 'Beef mince');
    expect(mince.amount, 665);
    expect(mince.unit, IngredientUnit.gram);
    final curry = lines.firstWhere((line) => line.name == 'Curry powder');
    expect((curry.amount, curry.unit), (4 / 3, IngredientUnit.tablespoon));
  });

  test('a line with no amount is a bare name, never scaled', () {
    final salt = recipeMealLines(
      bobotie,
      RecipeScale(people: 12, servings: 6),
    ).firstWhere((line) => line.name == 'Salt');
    expect(salt.amount, isNull);
    expect(salt.unit, isNull);
  });

  test('a unit this build does not know keeps the name, not a false count', () {
    final recipe = bobotie.copyWith(
      ingredients: const [
        RecipeIngredient(name: 'Saffron', quantity: 2, unit: 'pinch'),
      ],
    );
    final line = recipeMealLines(recipe, RecipeScale.asWritten(6)).single;
    expect((line.name, line.amount, line.unitCode), ('Saffron', null, null));
  });

  test('no more lines than a meal may hold', () {
    final recipe = bobotie.copyWith(
      ingredients: [
        for (var line = 0; line < MealIngredient.lineLimit + 5; line++)
          RecipeIngredient(name: 'Line $line', quantity: 1),
      ],
    );
    expect(
      recipeMealLines(recipe, RecipeScale.asWritten(6)),
      hasLength(MealIngredient.lineLimit),
    );
  });
}
