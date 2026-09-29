import 'package:flutter/foundation.dart';

import 'lunch_board.dart';
import 'lunch_cost.dart';
import 'lunch_item.dart';
import 'lunch_price.dart';
import 'lunch_slot.dart';
import 'lunch_suggestions.dart';

/// Something cheaper for the same compartment, on the days a child's week
/// still has it.
@immutable
class LunchCheaperSwap {
  LunchCheaperSwap({
    required this.from,
    required this.to,
    required this.slot,
    required List<int> weekdays,
    required this.savingPerBox,
  }) : weekdays = List.unmodifiable(weekdays);

  final LunchItem from;
  final LunchSuggestion to;
  final LunchSlot slot;

  /// The ISO weekdays, today on, whose box holds [from].
  final List<int> weekdays;
  final LunchCost savingPerBox;

  LunchCost get saving => savingPerBox * weekdays.length;
}

/// Cheaper swaps for one child's week (lunch-box ADR-0007). A swap is offered
/// only from the same slot, only from the child's *suggested* items — so
/// never one that is unsafe for them or that they dislike (lunch-box
/// ADR-0001, ADR-0003) — only for something priced and cheaper per box, and
/// only when its taste score is no more than [tasteTolerance] below what it
/// replaces. The one offered per item is the biggest saving, then the better
/// eaten, then the name.
abstract final class LunchCheaperSwaps {
  static const tasteTolerance = 1.0;

  static List<LunchCheaperSwap> find({
    required LunchBoard board,
    required LunchChildWeek childWeek,
    required Map<String, LunchPrice> prices,
  }) {
    final daysByItem = <String, List<int>>{};
    final slotOf = <String, LunchSlot>{};
    for (final day in childWeek.days) {
      if (day.date.isBefore(board.today)) continue;
      for (final (slot, pick) in day.box.filled) {
        daysByItem.putIfAbsent(pick.itemId, () => []).add(day.date.weekday);
        slotOf[pick.itemId] = slot;
      }
    }
    final swaps = <LunchCheaperSwap>[];
    for (final MapEntry(key: itemId, value: weekdays) in daysByItem.entries) {
      final from = board.libraryById[itemId];
      final price = prices[itemId];
      final slot = slotOf[itemId];
      if (from == null || price == null || slot == null) continue;
      final swap = _bestFor(
        from: from,
        slot: slot,
        fromCost: price.perBox,
        fromTaste: childWeek.taste.of(itemId).score,
        ranked: childWeek.rank(slot, board.library),
        prices: prices,
      );
      if (swap == null) continue;
      swaps.add(
        LunchCheaperSwap(
          from: from,
          to: swap.$1,
          slot: slot,
          weekdays: weekdays,
          savingPerBox: swap.$2,
        ),
      );
    }
    return swaps..sort((a, b) {
      final bySaving = b.saving.compareTo(a.saving);
      return bySaving != 0
          ? bySaving
          : a.from.nameKey.compareTo(b.from.nameKey);
    });
  }

  static (LunchSuggestion, LunchCost)? _bestFor({
    required LunchItem from,
    required LunchSlot slot,
    required LunchCost fromCost,
    required double fromTaste,
    required RankedLunchItems ranked,
    required Map<String, LunchPrice> prices,
  }) {
    (LunchSuggestion, LunchCost)? best;
    for (final candidate in ranked.suggested) {
      final price = prices[candidate.item.id];
      if (candidate.item.id == from.id || price == null) continue;
      if (candidate.taste.score < fromTaste - tasteTolerance) continue;
      final saving = fromCost - price.perBox;
      if (saving.millicents <= 0) continue;
      if (best == null || _isBetter(candidate, saving, best)) {
        best = (candidate, saving);
      }
    }
    return best;
  }

  static bool _isBetter(
    LunchSuggestion candidate,
    LunchCost saving,
    (LunchSuggestion, LunchCost) best,
  ) {
    final bySaving = saving.compareTo(best.$2);
    if (bySaving != 0) return bySaving > 0;
    final byTaste = candidate.taste.score.compareTo(best.$1.taste.score);
    if (byTaste != 0) return byTaste > 0;
    return candidate.item.nameKey.compareTo(best.$1.item.nameKey) < 0;
  }
}
