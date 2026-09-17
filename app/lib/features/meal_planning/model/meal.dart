import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/text/normalised_name.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

/// Something the household eats, at `households/{id}/meals/{mealId}`
/// (meal-planning ADR-0001).
///
/// The library is not a list somebody maintains — it is what has been typed
/// before. Typing a name that is not in it creates the meal; picking from it
/// reuses one. So free text and the library are the same thing.
@freezed
abstract class Meal with _$Meal {
  const factory Meal({
    @JsonKey(includeToJson: false) required String id,
    required String name,

    /// [name] normalised, stored so the household can be asked "have we typed
    /// this before" in one query. It is derived, never typed — `Meal.named`
    /// is the only way to make one (`ENG-02`: the same normaliser groceries
    /// ranks its chips with).
    required String nameKey,
    required String addedBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _Meal;

  const Meal._();

  /// The only way to build a meal from something a person typed, so the stored
  /// key and the stored name can never disagree.
  factory Meal.named({
    required String id,
    required String name,
    required String addedBy,
  }) => Meal(
    id: id,
    name: name.trim(),
    nameKey: normalisedName(name),
    addedBy: addedBy,
  );

  factory Meal.fromJson(Map<String, Object?> json) => _$MealFromJson(json);
}
