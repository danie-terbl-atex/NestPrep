import 'package:freezed_annotation/freezed_annotation.dart';

import 'meal_ingredient.dart';

/// A meal's `ingredients` as stored, parsed line by line (meal-planning
/// ADR-0002, `ENG-09`).
///
/// The rules can check the list's size but not each line's shape, so a line
/// that is not a name with an optional positive amount is dropped here rather
/// than failing the whole library — one bad line from an old build must not
/// take every meal off the screen. What is kept is always well formed.
class MealIngredientsConverter
    implements JsonConverter<List<MealIngredient>, List<Object?>?> {
  const MealIngredientsConverter();

  @override
  List<MealIngredient> fromJson(List<Object?>? json) => [
    for (final line in json ?? const <Object?>[]) ?_parse(line),
  ];

  @override
  List<Object?> toJson(List<MealIngredient> lines) => [
    for (final line in lines) line.toJson(),
  ];

  static MealIngredient? _parse(Object? line) {
    if (line is! Map<String, Object?>) return null;
    final name = line['name'];
    final amount = line['amount'];
    final unit = line['unit'];
    if (name is! String || name.trim().isEmpty) return null;
    if (amount != null && (amount is! num || amount <= 0)) return null;
    if (unit != null && unit is! String) return null;
    return MealIngredient(
      name: name,
      amount: (amount as num?)?.toDouble(),
      unitCode: unit as String?,
    );
  }
}
