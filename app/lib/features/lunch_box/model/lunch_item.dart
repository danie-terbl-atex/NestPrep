import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/text/normalised_name.dart';
import '../../family_profiles/model/allergen.dart';
import 'lunch_slot.dart';

part 'lunch_item.freezed.dart';
part 'lunch_item.g.dart';

/// Something that goes in a lunch box, at `households/{id}/lunchItems/{itemId}`
/// (lunch-box ADR-0001). The household's library: seeded once from
/// `LunchSeedCatalogue`, then grown by what the family adds.
///
/// It carries what it contains from the fixed allergen vocabulary, because
/// that is what a box is checked against — by the app to flag it and by the
/// rules to refuse it. An item is never deleted, only put away ([archived]):
/// past weeks' eaten-or-not history points at it.
@freezed
abstract class LunchItem with _$LunchItem {
  const factory LunchItem({
    @JsonKey(includeToJson: false) required String id,
    required String name,

    /// [name] normalised — derived, never typed (`Meal.named`'s reasoning).
    required String nameKey,

    /// The slot it goes in, as stored. Read through [slot], which is null for
    /// a slot this build does not know (`BE-10`).
    @JsonKey(name: 'slot') required String slotName,

    /// Allergen codes (`Allergen.name`). Kept as stored so a code a newer
    /// build added still travels into a box and still reaches the rules.
    @Default(<String>[]) List<String> allergens,

    /// Worth making ahead on Sunday — muffins, boiled eggs, cut veg.
    @Default(false) bool prepAhead,

    /// How to make it ahead, shown on the prep list.
    String? prepNote,
    @Default(false) bool archived,

    /// Set on the items the library was seeded with, so re-seeding recognises
    /// them; null for the household's own.
    String? seedKey,
    required String addedBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _LunchItem;

  const LunchItem._();

  factory LunchItem.fromJson(Map<String, Object?> json) =>
      _$LunchItemFromJson(json);

  /// The one way to build an item from what somebody typed, so the stored key
  /// and name never disagree.
  factory LunchItem.named({
    required String id,
    required String name,
    required LunchSlot slot,
    required Set<Allergen> allergens,
    required String addedBy,
    bool prepAhead = false,
    String? prepNote,
    String? seedKey,
  }) {
    final note = prepNote?.trim();
    return LunchItem(
      id: id,
      name: name.trim(),
      nameKey: normalisedName(name),
      slotName: slot.name,
      allergens: [
        for (final allergen in Allergen.values)
          if (allergens.contains(allergen)) allergen.name,
      ],
      prepAhead: prepAhead,
      prepNote: note == null || note.isEmpty ? null : note,
      seedKey: seedKey,
      addedBy: addedBy,
    );
  }

  static const nameLimit = 60;
  static const prepNoteLimit = 140;

  LunchSlot? get slot => LunchSlot.fromName(slotName);

  /// The allergens this build knows; see [allergens] for the rest.
  Set<Allergen> get knownAllergens => {
    for (final code in allergens) ?Allergen.fromCode(code),
  };
}
