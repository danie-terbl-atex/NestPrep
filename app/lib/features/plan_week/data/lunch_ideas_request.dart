import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../model/packing_preference.dart';
import 'lunch_idea_drafter.dart';

/// What the phone sends `draftLunchIdeas` (lunch-box ADR-0012): the week,
/// whose lunches, the brief's packing choices and the lunchbox aisle within
/// the contract's bounds (ADR-0013). Pure, so the shape is tested without
/// Functions.
abstract final class LunchIdeasRequest {
  static const shelfLimit = 12;
  static const namesPerShelf = 6;

  static Map<String, Object?> toWire({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required PackingChoice packing,
    required List<AisleShelfNames> aisle,
  }) => {
    'householdId': householdId,
    'week': week.key,
    'childIds': [...childIds]..sort(),
    'slots': wireNames(LunchSlot.values, packing.slots),
    'preferences': wireNames(PackingPreference.values, packing.preferences),
    'aisle': [
      for (final shelf in aisle.take(shelfLimit))
        {
          'slot': shelf.slot.name,
          'title': _cut(shelf.title, 60),
          'products': [
            for (final name in shelf.products.take(namesPerShelf))
              _cut(name, 120),
          ],
        },
    ],
  };

  static String _cut(String text, int longest) =>
      text.length <= longest ? text : text.substring(0, longest);
}
