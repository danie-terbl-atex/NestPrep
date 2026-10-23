import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/recipes/model/kitchen_fraction.dart';
import 'package:nestprep/features/recipes/model/recipe_amount.dart';
import 'package:nestprep/features/recipes/model/recipe_scale.dart';

/// Scaling is presentation arithmetic (recipes ADR-0003 §5): every quantity
/// times people ÷ servings, rounded for reading — fractions for spoons and
/// cups, whole grams, counts to the half — and a unit moves only to an
/// amount a cook can measure.
void main() {
  String read(num quantity, IngredientUnit? unit, {double factor = 1}) {
    final amount = RecipeAmount.scaled(quantity, unit: unit, factor: factor);
    return '${amount.number} ${amount.unit?.code ?? ''}'.trim();
  }

  group('the factor is people over servings', () {
    test('a six-serving pot cooked for four is two thirds', () {
      final scale = RecipeScale(people: 4, servings: 6);
      expect(scale.factor, closeTo(2 / 3, 1e-9));
      expect(scale.factorText, '2/3');
    });

    test('a four-serving pot cooked for ten is two and a half', () {
      expect(RecipeScale(people: 10, servings: 4).factorText, '2 1/2');
    });

    test('a factor no kitchen fraction is near reads as one decimal', () {
      expect(RecipeScale(people: 7, servings: 6).factorText, '1.2');
    });

    test('people stay between one and twenty-four', () {
      expect(RecipeScale(people: 0, servings: 4).people, 1);
      expect(RecipeScale(people: 40, servings: 4).people, 24);
      expect(RecipeScale(people: 1, servings: 4).canRemove, isFalse);
      expect(RecipeScale(people: 24, servings: 4).canAdd, isFalse);
    });
  });

  group('grams and millilitres', () {
    test('are whole below a hundred and to the nearest five above', () {
      expect(read(250, IngredientUnit.gram, factor: 2 / 3), '165 g');
      expect(read(30, IngredientUnit.gram, factor: 2 / 3), '20 g');
      expect(read(1, IngredientUnit.gram, factor: 0.25), '1 g');
    });

    test('climb into kilograms and litres from a thousand', () {
      expect(read(500, IngredientUnit.gram, factor: 3), '1.5 kg');
      expect(read(750, IngredientUnit.millilitre, factor: 2), '1.5 l');
    });

    test('and come back down below one', () {
      expect(read(1, IngredientUnit.kilogram, factor: 2 / 3), '665 g');
      expect(read(1, IngredientUnit.litre, factor: 0.5), '500 ml');
    });

    test('kilograms read to the nearest fifty grams', () {
      expect(read(1, IngredientUnit.kilogram, factor: 10 / 6), '1.65 kg');
      expect(read(2, IngredientUnit.kilogram), '2 kg');
    });
  });

  group('spoons and cups', () {
    test('read as the fractions a measuring set has', () {
      expect(read(0.5, IngredientUnit.cup, factor: 1.5), '3/4 cup');
      expect(read(1, IngredientUnit.cup, factor: 2 / 3), '2/3 cup');
      expect(read(1, IngredientUnit.teaspoon, factor: 1.5), '1 1/2 tsp');
    });

    test('keep the unit the recipe wrote when it still measures', () {
      expect(read(1 / 3, IngredientUnit.cup), '1/3 cup');
      expect(read(4, IngredientUnit.teaspoon), '4 tsp');
      expect(read(3, IngredientUnit.tablespoon, factor: 2), '6 tbsp');
    });

    test('move down when the amount is under what the unit measures', () {
      expect(read(0.5, IngredientUnit.cup, factor: 0.25), '2 tbsp');
      expect(read(1, IngredientUnit.tablespoon, factor: 1 / 3), '1 tsp');
    });

    test('move up only onto an amount the larger one measures', () {
      expect(read(2, IngredientUnit.tablespoon, factor: 8), '1 cup');
      expect(read(2, IngredientUnit.teaspoon, factor: 3), '2 tbsp');
      expect(read(4, IngredientUnit.teaspoon, factor: 3), '1/4 cup');
    });

    test('a pinch never rounds away to nothing', () {
      expect(read(0.25, IngredientUnit.teaspoon, factor: 1 / 6), '1/8 tsp');
    });
  });

  group('things you count', () {
    test('go to the nearest half up to ten, whole after', () {
      expect(read(2, null, factor: 2 / 3), '1 1/2');
      expect(read(3, null, factor: 2.5), '7 1/2');
      expect(read(6, null, factor: 2.5), '15');
    });

    test('and to a quarter below one', () {
      expect(read(1, null, factor: 0.25), '1/4');
      expect(read(1, null, factor: 0.1), '1/4');
    });

    test('tins and packs round the same way', () {
      expect(read(1, IngredientUnit.tin, factor: 2 / 3), '3/4 tin');
      expect(read(2, IngredientUnit.pack, factor: 2.5), '5 pack');
    });
  });

  test(
    'a fraction is written for the page to set, anything else as a number',
    () {
      expect(KitchenFraction.text(2.75), '2 3/4');
      expect(KitchenFraction.text(0.125), '1/8');
      expect(KitchenFraction.text(12), '12');
      expect(KitchenFraction.round(1.3), closeTo(4 / 3, 1e-9));
    },
  );
}
