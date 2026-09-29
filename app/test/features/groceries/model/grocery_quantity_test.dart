import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_amount.dart';
import 'package:nestprep/features/groceries/model/grocery_quantity.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/shared/copy/grocery_plan_copy.dart';

String? said(List<GroceryAmount> amounts) =>
    GroceryPlanCopy.quantity(GroceryQuantity.sum(amounts));

/// Groceries ADR-0003: amounts add up within a dimension, round up to what a
/// shop sells, and never pretend to a precision nobody has.
void main() {
  test('grams and kilograms add up to one line', () {
    expect(
      said(const [
        GroceryAmount(500, IngredientUnit.gram),
        GroceryAmount(1, IngredientUnit.kilogram),
      ]),
      '1.5 kg',
    );
  });

  test('a tin and a pack never add up to anything', () {
    expect(
      said(const [
        GroceryAmount(2, IngredientUnit.tin),
        GroceryAmount(1, IngredientUnit.pack),
        GroceryAmount(1, IngredientUnit.tin),
      ]),
      '1 pack + 3 tins',
    );
  });

  test('rounds up to what a shop sells, never to fake precision', () {
    expect(said(const [GroceryAmount(37, IngredientUnit.gram)]), '40 g');
    expect(said(const [GroceryAmount(120, IngredientUnit.gram)]), '150 g');
    expect(said(const [GroceryAmount(950, IngredientUnit.gram)]), '950 g');
    expect(said(const [GroceryAmount(980, IngredientUnit.gram)]), '1 kg');
    expect(
      said(const [GroceryAmount(1.37, IngredientUnit.kilogram)]),
      '1.4 kg',
    );
    expect(
      said(const [GroceryAmount(250, IngredientUnit.millilitre)]),
      '250 ml',
    );
    expect(
      said(const [
        GroceryAmount(750, IngredientUnit.millilitre),
        GroceryAmount(1, IngredientUnit.litre),
      ]),
      '1.8 l',
    );
  });

  test('half an onion twice is one onion; a tin and a half is two', () {
    expect(said(const [GroceryAmount(0.5), GroceryAmount(0.5)]), '×1');
    expect(said(const [GroceryAmount(1.5, IngredientUnit.tin)]), '2 tins');
    expect(said(const [GroceryAmount(1, IngredientUnit.loaf)]), '1 loaf');
    expect(said(const [GroceryAmount(2, IngredientUnit.loaf)]), '2 loaves');
  });

  test('a float that is really a whole number is not rounded past it', () {
    // 0.1 + 0.2 is 0.30000000000000004; three of them must not make 2.
    expect(
      said(const [
        GroceryAmount(0.1, IngredientUnit.kilogram),
        GroceryAmount(0.2, IngredientUnit.kilogram),
        GroceryAmount(0.7, IngredientUnit.kilogram),
      ]),
      '1 kg',
    );
    expect(
      said(const [
        GroceryAmount(1 / 3),
        GroceryAmount(1 / 3),
        GroceryAmount(1 / 3),
      ]),
      '×1',
    );
  });

  test('kitchen measures are reasons, not shopping amounts', () {
    expect(
      said(const [
        GroceryAmount(2, IngredientUnit.tablespoon),
        GroceryAmount(1, IngredientUnit.cup),
      ]),
      isNull,
    );
    expect(
      said(const [
        GroceryAmount(2, IngredientUnit.tablespoon),
        GroceryAmount(1, IngredientUnit.bottle),
      ]),
      '1 bottle',
    );
  });

  test('nothing to add up says nothing', () {
    expect(said(const []), isNull);
  });
}
