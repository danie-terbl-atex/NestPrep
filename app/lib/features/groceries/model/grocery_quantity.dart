import 'package:flutter/foundation.dart';

import '../../meal_planning/model/ingredient_unit.dart';
import 'grocery_amount.dart';

/// A week's amounts of one thing, added up the way a shop sells it
/// (groceries ADR-0003): within a dimension only, rounded up once, and with
/// kitchen measures left out.
///
/// *500 g + 1 kg* is one part, *1.5 kg*; *2 tins + 1 pack* is two.
@immutable
class GroceryQuantity {
  const GroceryQuantity._(this.parts);

  factory GroceryQuantity.sum(Iterable<GroceryAmount> amounts) {
    final totals = <UnitDimension, double>{};
    for (final amount in amounts) {
      if (amount.unit?.isShoppable == false) continue;
      totals[amount.dimension] =
          (totals[amount.dimension] ?? 0) + amount.inBaseUnits;
    }
    return GroceryQuantity._(
      List.unmodifiable([
        for (final dimension in UnitDimension.values)
          if (totals[dimension] case final total? when total > 0)
            _rounded(dimension, total),
      ]),
    );
  }

  /// In the vocabulary's order: mass, volume, count, then the whole units.
  final List<GroceryAmount> parts;

  bool get isEmpty => parts.isEmpty;

  static const _epsilon = 1e-9;

  static GroceryAmount _rounded(
    UnitDimension dimension,
    double total,
  ) => switch (dimension) {
    UnitDimension.mass => _metric(
      total,
      small: IngredientUnit.gram,
      large: IngredientUnit.kilogram,
    ),
    UnitDimension.volume => _metric(
      total,
      small: IngredientUnit.millilitre,
      large: IngredientUnit.litre,
    ),
    UnitDimension.count => GroceryAmount(_wholeUp(total)),
    UnitDimension.pack => GroceryAmount(_wholeUp(total), IngredientUnit.pack),
    UnitDimension.tin => GroceryAmount(_wholeUp(total), IngredientUnit.tin),
    UnitDimension.loaf => GroceryAmount(_wholeUp(total), IngredientUnit.loaf),
    UnitDimension.bunch => GroceryAmount(_wholeUp(total), IngredientUnit.bunch),
    UnitDimension.bottle => GroceryAmount(
      _wholeUp(total),
      IngredientUnit.bottle,
    ),
    // Filtered out before rounding; never a part.
    UnitDimension.kitchen => throw StateError('not a shopping amount'),
  };

  /// Up to the next 10 under 100, the next 50 under 1000, and the next tenth
  /// of the larger unit from there.
  static GroceryAmount _metric(
    double base, {
    required IngredientUnit small,
    required IngredientUnit large,
  }) {
    if (base < 100) return GroceryAmount(_upTo(base, 10), small);
    final smallStep = _upTo(base, 50);
    if (smallStep < large.inBaseUnits) return GroceryAmount(smallStep, small);
    final inLarge = _upTo(base / large.inBaseUnits, 0.1);
    return GroceryAmount(_trimmed(inLarge), large);
  }

  static double _wholeUp(double value) =>
      (value - _epsilon).ceilToDouble().clamp(1, double.infinity);

  static double _upTo(double value, double step) =>
      ((value / step) - _epsilon).ceilToDouble() * step;

  /// 1.2000000000000002 is 1.2 — the tenths are what was meant.
  static double _trimmed(double value) => (value * 10).roundToDouble() / 10;
}
