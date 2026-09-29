import 'package:freezed_annotation/freezed_annotation.dart';

import '../../family_profiles/model/allergen.dart';
import 'lunch_item.dart';

part 'lunch_pick.freezed.dart';
part 'lunch_pick.g.dart';

/// One item in one compartment of a box, as the plan stores it (lunch-box
/// ADR-0001): the item it came from, and a copy of its name and allergens.
///
/// The copy is what the rules check — they cannot look up an item per slot —
/// and what a kid's tablet shows without reading the library. The library
/// stays the truth for flagging: the board re-checks every pick against the
/// item as it is now, so an item that gains an allergen later is flagged in
/// every week it is already in.
@freezed
abstract class LunchPick with _$LunchPick {
  const factory LunchPick({
    required String itemId,
    required String name,
    @Default(<String>[]) List<String> allergens,
  }) = _LunchPick;

  const LunchPick._();

  factory LunchPick.fromJson(Map<String, Object?> json) =>
      _$LunchPickFromJson(json);

  factory LunchPick.of(LunchItem item) =>
      LunchPick(itemId: item.id, name: item.name, allergens: item.allergens);

  Set<Allergen> get knownAllergens => {
    for (final code in allergens) ?Allergen.fromCode(code),
  };
}
