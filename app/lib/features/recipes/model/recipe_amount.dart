import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../meal_planning/model/ingredient_unit.dart';
import 'kitchen_fraction.dart';

/// One ingredient's quantity at the scale it is being cooked at, rounded for
/// reading (recipes ADR-0003 §5): grams and millilitres whole, kilograms and
/// litres to the nearest 50, spoons and cups as the fractions a measuring
/// set has, and things you count to the nearest half.
///
/// A unit moves when the scaled amount reads better in its neighbour — 1 500 g
/// is 1.5 kg, 1/8 cup is 2 tbsp, 16 tbsp is 1 cup — but only to an amount a
/// cook can measure, so 1/3 cup stays 1/3 cup and 4 tsp never becomes
/// 1 1/3 tbsp.
@immutable
final class RecipeAmount {
  const RecipeAmount._(this.value, this.unit);

  /// [quantity] in [unit], multiplied by [factor]. A null [unit] is a count —
  /// three onions — or a unit this build does not know, which is rounded as
  /// a count and keeps its own word.
  factory RecipeAmount.scaled(
    num quantity, {
    required IngredientUnit? unit,
    double factor = 1,
  }) {
    final raw = quantity * factor;
    return switch (unit) {
      IngredientUnit(dimension: UnitDimension.mass) => _metric(
        raw * unit.inBaseUnits,
        small: IngredientUnit.gram,
        large: IngredientUnit.kilogram,
      ),
      IngredientUnit(dimension: UnitDimension.volume) => _metric(
        raw * unit.inBaseUnits,
        small: IngredientUnit.millilitre,
        large: IngredientUnit.litre,
      ),
      IngredientUnit(dimension: UnitDimension.kitchen) => _kitchen(raw, unit),
      _ => RecipeAmount._(_count(raw), unit),
    };
  }

  /// The amount, already rounded.
  final double value;

  /// What it is measured in, or null for a plain count.
  final IngredientUnit? unit;

  /// [value] as it is read: `1.5` kg, `250` g, `1 1/2` cups, `3` onions —
  /// fractions set with the `frac` feature (`KitchenFraction`).
  String get number => switch (unit) {
    IngredientUnit.kilogram || IngredientUnit.litre => _decimal(value),
    IngredientUnit.gram || IngredientUnit.millilitre => '${value.round()}',
    _ => KitchenFraction.text(value),
  };

  /// A metric amount in its base unit (grams or millilitres): whole below
  /// 100, to the nearest 5 above it, and in the larger unit from 1 000 up.
  static RecipeAmount _metric(
    double base, {
    required IngredientUnit small,
    required IngredientUnit large,
  }) {
    final rounded = base < 100
        ? math.max(1.0, base.roundToDouble())
        : (base / 5).roundToDouble() * 5;
    if (rounded < 1000) return RecipeAmount._(rounded, small);
    return RecipeAmount._((base / 50).roundToDouble() * 50 / 1000, large);
  }

  /// Spoons and cups, kept in the unit the recipe wrote unless the amount
  /// falls below what that unit measures or lands exactly on a larger one.
  static RecipeAmount _kitchen(double amount, IngredientUnit unit) {
    final teaspoons = amount * unit.inBaseUnits;
    var index = _spoons.indexOf(unit);
    while (index > 0 &&
        teaspoons / _spoons[index].inBaseUnits < _least[index]) {
      index--;
    }
    while (index < _spoons.length - 1) {
      final larger = teaspoons / _spoons[index + 1].inBaseUnits;
      if (larger < _least[index + 1] ||
          !KitchenFraction.isMultipleOf(larger, _steps[index + 1])) {
        break;
      }
      index++;
    }
    final measure = _spoons[index];
    return RecipeAmount._(
      KitchenFraction.round(teaspoons / measure.inBaseUnits),
      measure,
    );
  }

  static const _spoons = [
    IngredientUnit.teaspoon,
    IngredientUnit.tablespoon,
    IngredientUnit.cup,
  ];

  /// The least of each that is worth measuring in it: under a tablespoon is
  /// teaspoons, under a quarter cup is tablespoons.
  static const _least = [0.0, 1.0, 0.25];

  /// What an amount must be a whole number of to move up into each: a half
  /// tablespoon, a quarter cup.
  static const _steps = [1.0, 0.5, 0.25];

  /// Things you count, and things a shop sells whole: a quarter below one,
  /// a half up to ten, whole numbers after that.
  static double _count(double value) {
    if (value >= 10) return value.roundToDouble();
    if (value >= 1) return (value * 2).roundToDouble() / 2;
    return math.max(0.25, (value * 4).roundToDouble() / 4);
  }

  static String _decimal(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  bool operator ==(Object other) =>
      other is RecipeAmount && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);

  @override
  String toString() => 'RecipeAmount($number ${unit?.code ?? ''})';
}
