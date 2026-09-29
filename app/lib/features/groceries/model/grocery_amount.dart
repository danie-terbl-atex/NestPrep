import 'package:flutter/foundation.dart';

import '../../meal_planning/model/ingredient_unit.dart';

/// How much of something, in a unit from the one vocabulary
/// (groceries ADR-0003). A null unit is a plain count.
@immutable
class GroceryAmount {
  const GroceryAmount(this.value, [this.unit]);

  final double value;
  final IngredientUnit? unit;

  UnitDimension get dimension => unit?.dimension ?? UnitDimension.count;

  /// The amount in its dimension's smallest unit — 1.5 kg is 1500.
  double get inBaseUnits => value * (unit?.inBaseUnits ?? 1);

  @override
  bool operator ==(Object other) =>
      other is GroceryAmount && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);
}
