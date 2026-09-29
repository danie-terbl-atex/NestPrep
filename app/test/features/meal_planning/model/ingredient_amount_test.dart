import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_amount.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredient.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredients_converter.dart';

/// What a person may type as an amount, and how a stored line is read back
/// (meal-planning ADR-0002).
void main() {
  group('an amount somebody typed', () {
    test('reads the ways people write a number', () {
      expect(parseIngredientAmount('2'), 2);
      expect(parseIngredientAmount(' 1.5 '), 1.5);
      expect(parseIngredientAmount('1,5'), 1.5);
      expect(parseIngredientAmount('½'), 0.5);
      expect(parseIngredientAmount('1/4'), 0.25);
      expect(parseIngredientAmount('1 1/2'), 1.5);
      expect(parseIngredientAmount('2½'), 2.5);
    });

    test('an empty field is no amount, not a mistake', () {
      expect(parseIngredientAmount(''), isNull);
      expect(parseIngredientAmount('   '), isNull);
    });

    test('anything that is not a positive number is said, never dropped', () {
      for (final typed in ['a few', '0', '-1', '1/0', '100000', 'two']) {
        expect(
          () => parseIngredientAmount(typed),
          throwsFormatException,
          reason: typed,
        );
      }
    });
  });

  group('a line as typed', () {
    test('is trimmed, and carries no unit when there is no amount', () {
      final line = MealIngredient.typed(
        name: '  Onions ',
        unit: IngredientUnit.kilogram,
      );
      expect(line.name, 'Onions');
      expect(line.amount, isNull);
      expect(line.unit, isNull);
      expect(line.key, 'onions');
    });

    test('a unit code this build does not know reads as no unit', () {
      expect(
        const MealIngredient(name: 'Rice', amount: 1, unitCode: 'sack').unit,
        isNull,
      );
    });
  });

  group('the stored list', () {
    const converter = MealIngredientsConverter();

    test('round-trips what the app writes', () {
      final lines = [
        MealIngredient.typed(
          name: 'Mince',
          amount: 500,
          unit: IngredientUnit.gram,
        ),
        MealIngredient.typed(name: 'Salt'),
      ];
      expect(converter.fromJson(converter.toJson(lines)), lines);
    });

    test('drops a malformed line instead of failing the whole library', () {
      final read = converter.fromJson([
        {'name': 'Mince', 'amount': 500, 'unit': 'g'},
        {'name': '', 'amount': 1},
        {'amount': 2},
        {'name': 'Rice', 'amount': -1},
        {'name': 'Oil', 'unit': 3},
        'not a line',
        null,
        {'name': 'Tins', 'amount': 2, 'unit': 'tin'},
      ]);
      expect([for (final line in read) line.name], ['Mince', 'Tins']);
      expect(read.first.amount, 500.0);
    });

    test('a meal with no list has no ingredients', () {
      expect(converter.fromJson(null), isEmpty);
    });
  });
}
