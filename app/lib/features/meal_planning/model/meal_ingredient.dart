import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/text/normalised_name.dart';
import 'ingredient_unit.dart';

part 'meal_ingredient.freezed.dart';
part 'meal_ingredient.g.dart';

/// One line of what a meal needs (meal-planning ADR-0002): a name, and how much
/// when somebody knows. Stored inside the meal's `ingredients` list.
@freezed
abstract class MealIngredient with _$MealIngredient {
  const factory MealIngredient({
    required String name,

    /// For the meal as the household cooks it; null when nobody said.
    double? amount,

    /// The unit's code as stored. Read through [unit], which is null for no
    /// unit and for a code this build does not know (`BE-10`).
    @JsonKey(name: 'unit') String? unitCode,
  }) = _MealIngredient;

  const MealIngredient._();

  factory MealIngredient.fromJson(Map<String, Object?> json) =>
      _$MealIngredientFromJson(json);

  /// The one way to build a line from what somebody typed: trimmed, and with
  /// no unit when there is no amount for it to measure.
  factory MealIngredient.typed({
    required String name,
    double? amount,
    IngredientUnit? unit,
  }) => MealIngredient(
    name: name.trim(),
    amount: amount,
    unitCode: amount == null ? null : unit?.code,
  );

  /// How long a name may be — the same bound a grocery item's name has.
  static const nameLimit = 60;

  /// How many lines one meal may carry; the rules hold the same number.
  static const lineLimit = 40;

  IngredientUnit? get unit => IngredientUnit.fromCode(unitCode);

  /// What groceries merges this line on (groceries ADR-0002).
  String get key => normalisedName(name);
}
