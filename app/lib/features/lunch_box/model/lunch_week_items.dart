import 'package:flutter/foundation.dart';

import 'lunch_item.dart';
import 'lunch_plan.dart';
import 'lunch_slot.dart';

/// One thing the household's boxes need this week, summed across every
/// child — the read API groceries phase 2 fills the list from and the Sunday
/// prep list is built on (lunch-box overview, *Contracts*).
@immutable
class LunchWeekItem {
  const LunchWeekItem({
    required this.itemId,
    required this.name,
    required this.slot,
    required this.portions,
    required this.childIds,
    required this.allergens,
    this.prepAhead = false,
    this.prepNote,
  });

  final String itemId;

  /// The library's name where the item still exists, else the name the plan
  /// copied.
  final String name;

  /// Null for a slot this build does not know.
  final LunchSlot? slot;

  /// How many boxes hold it this week.
  final int portions;

  /// Whose boxes, each once, in the order first met.
  final List<String> childIds;

  /// Allergen codes, as the library has them.
  final List<String> allergens;
  final bool prepAhead;
  final String? prepNote;
}

/// Sums a week's plans into what the household needs, one row per item.
///
/// Pure and bounded by its input — the week's plans and the library, both
/// already on screen — so a reader that has them pays nothing more
/// (`FE-12`, `BE-08`).
abstract final class LunchWeekItems {
  static List<LunchWeekItem> from({
    required Iterable<LunchPlan> plans,
    required Iterable<LunchItem> library,
  }) {
    final byId = {for (final item in library) item.id: item};
    final portions = <String, int>{};
    final children = <String, List<String>>{};
    final firstPick =
        <String, ({String name, String slot, List<String> allergens})>{};
    for (final plan in plans) {
      for (final MapEntry(:key, :value) in plan.slots.entries) {
        final id = value.itemId;
        portions[id] = (portions[id] ?? 0) + 1;
        final whose = children.putIfAbsent(id, () => []);
        if (!whose.contains(plan.childId)) whose.add(plan.childId);
        firstPick.putIfAbsent(
          id,
          () => (
            name: value.name,
            slot: key.substring(key.indexOf('_') + 1),
            allergens: value.allergens,
          ),
        );
      }
    }
    final rows = [
      for (final MapEntry(key: id, value: count) in portions.entries)
        _row(id, count, children[id]!, firstPick[id]!, byId[id]),
    ];
    return rows..sort(_bySlotThenName);
  }

  static LunchWeekItem _row(
    String itemId,
    int portions,
    List<String> childIds,
    ({String name, String slot, List<String> allergens}) pick,
    LunchItem? item,
  ) => LunchWeekItem(
    itemId: itemId,
    name: item?.name ?? pick.name,
    slot: item?.slot ?? LunchSlot.fromName(pick.slot),
    portions: portions,
    childIds: List.unmodifiable(childIds),
    allergens: List.unmodifiable(item?.allergens ?? pick.allergens),
    prepAhead: item?.prepAhead ?? false,
    prepNote: item?.prepNote,
  );

  static int _bySlotThenName(LunchWeekItem a, LunchWeekItem b) {
    final aSlot = a.slot?.index ?? LunchSlot.values.length;
    final bSlot = b.slot?.index ?? LunchSlot.values.length;
    if (aSlot != bSlot) return aSlot.compareTo(bSlot);
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
