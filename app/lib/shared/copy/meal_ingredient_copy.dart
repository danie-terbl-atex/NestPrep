import '../../features/meal_planning/model/ingredient_unit.dart';
import '../../features/meal_planning/model/meal_ingredient.dart';

/// Every word the meal library says about what goes in a meal
/// (meal-planning ADR-0002), in its own file beside `app_copy.dart` (`FE-19`).
abstract final class MealIngredientCopy {
  static const whatGoesIn = 'What goes in it';
  static String title(String meal) => 'What goes in $meal';
  static const intro = 'These go on the grocery list when the meal is planned.';
  static String count(int lines) => switch (lines) {
    0 => 'No ingredients yet',
    1 => '1 ingredient',
    _ => '$lines ingredients',
  };
  static String openFor(String meal) => 'What goes in $meal';

  static const name = 'Ingredient';
  static const nameHint = 'Onions, mince, a loaf of bread…';
  static const amount = 'How much';
  static const amountHint = '2, 1.5 or ½';
  static const amountInvalid = 'Write a number, like 2, 1.5 or ½.';
  static const unit = 'Measured in';
  static const noUnit = 'each';
  static const add = 'Add ingredient';
  static String remove(String line) => 'Take $line off';
  static const save = 'Save';
  static const empty = 'Nothing listed yet. What does it need from the shops?';
  static String full(int limit) => 'A meal can list up to $limit ingredients.';

  static String unitName(IngredientUnit? unit) => unit?.code ?? noUnit;

  /// *500 g mince*, *2 onions* reads as *Onions · 2*; the line as a person
  /// typed it, not rounded — rounding is for the list (groceries ADR-0003).
  static String line(MealIngredient ingredient) {
    final amount = ingredient.amount;
    if (amount == null) return ingredient.name;
    final unit = ingredient.unit;
    final number = _number(amount);
    if (unit == null) return '${ingredient.name} · $number';
    final word = amount == 1 ? unit.code : _plurals[unit] ?? unit.code;
    return '${ingredient.name} · $number $word';
  }

  /// The whole units say themselves in the plural; the measures do not.
  static const _plurals = {
    IngredientUnit.pack: 'packs',
    IngredientUnit.tin: 'tins',
    IngredientUnit.loaf: 'loaves',
    IngredientUnit.bunch: 'bunches',
    IngredientUnit.bottle: 'bottles',
    IngredientUnit.cup: 'cups',
  };

  /// Up to two decimal places, and none when they would be zeros.
  static String _number(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
