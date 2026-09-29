import 'lunch_box.dart';
import 'lunch_packed_day.dart';
import 'lunch_pantry_entry.dart';
import 'lunch_pantry_week.dart';

/// What marking a box packed takes from the pantry, and what undoing it
/// gives back (lunch-box ADR-0006) — worked out before the batch, so the
/// batch never asks the rules for a pantry below zero or above its limit.
abstract final class LunchPackCounts {
  /// One of each thing in [box] the pantry still holds, by item id, and the
  /// same as a list — what the packed record keeps for the undo.
  static (Map<String, int>, List<String>) take(
    LunchBox box,
    LunchPantryWeek pantry,
  ) {
    final counts = <String, int>{};
    final taken = <String>[];
    for (final (_, pick) in box.filled) {
      final left = pantry.stockOf(pick.itemId) - (counts[pick.itemId] ?? 0);
      if (left <= 0) continue;
      counts[pick.itemId] = (counts[pick.itemId] ?? 0) + 1;
      taken.add(pick.itemId);
    }
    return (counts, taken);
  }

  /// What [packed] took, back to the entries still in the pantry that have
  /// room for it.
  static Map<String, int> giveBack(
    LunchPackedDay packed,
    LunchPantryWeek pantry,
  ) {
    final counts = <String, int>{};
    for (final itemId in packed.itemIds) {
      if (!pantry.has(itemId)) continue;
      final room =
          LunchPantryEntry.portionLimit -
          pantry.stockOf(itemId) -
          (counts[itemId] ?? 0);
      if (room > 0) counts[itemId] = (counts[itemId] ?? 0) + 1;
    }
    return counts;
  }
}
