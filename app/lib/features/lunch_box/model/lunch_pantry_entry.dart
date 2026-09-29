import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'lunch_pantry_entry.freezed.dart';
part 'lunch_pantry_entry.g.dart';

/// How much of one library item is in the house, at
/// `households/{id}/lunchPantry/{itemId}` (lunch-box ADR-0006) — counted in
/// boxes' worth, because "enough for four boxes" is what a parent can guess
/// about a bag of apples and what planning needs.
///
/// The document id is the lunch item's, so an item is in the pantry once.
/// Zero is kept, as *used up*, until somebody removes it — so topping it up
/// again is one tap.
@freezed
abstract class LunchPantryEntry with _$LunchPantryEntry {
  const factory LunchPantryEntry({
    /// The lunch item's id — also the document id.
    @JsonKey(includeToJson: false) required String id,
    @Default(0) int portions,
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _LunchPantryEntry;

  const LunchPantryEntry._();

  factory LunchPantryEntry.fromJson(Map<String, Object?> json) =>
      _$LunchPantryEntryFromJson(json);

  /// The most the rules keep: more than any pantry holds for school boxes.
  static const portionLimit = 99;

  /// What one tap of *a pack* adds.
  static const aPack = 5;

  String get itemId => id;

  bool get isUsedUp => portions <= 0;

  /// [value] kept inside what the rules allow.
  static int clamp(int value) => value.clamp(0, portionLimit);
}
