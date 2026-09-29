import 'package:flutter/foundation.dart';

import 'lunch_board.dart';
import 'lunch_box.dart';
import 'lunch_cost.dart';
import 'lunch_pick.dart';
import 'lunch_price.dart';

/// What one day's box costs: the priced things in it, and the ones with no
/// price yet (lunch-box ADR-0007).
@immutable
class LunchBoxCost {
  LunchBoxCost({required this.total, required List<LunchPick> unpriced})
    : unpriced = List.unmodifiable(unpriced);

  factory LunchBoxCost.of(LunchBox box, Map<String, LunchPrice> prices) {
    var total = LunchCost.zero;
    final unpriced = <LunchPick>[];
    for (final (_, pick) in box.filled) {
      final price = prices[pick.itemId];
      if (price == null) {
        unpriced.add(pick);
      } else {
        total += price.perBox;
      }
    }
    return LunchBoxCost(total: total, unpriced: unpriced);
  }

  final LunchCost total;
  final List<LunchPick> unpriced;

  /// A total with an unpriced thing in it is *at least* that much.
  bool get isAtLeast => unpriced.isNotEmpty;
}

/// One child's week in money: each school day's box and the week together.
@immutable
class LunchChildCost {
  LunchChildCost({
    required this.childId,
    required this.name,
    required Map<int, LunchBoxCost> days,
  }) : days = Map.unmodifiable(days);

  final String childId;
  final String name;

  /// ISO weekday → that day's box.
  final Map<int, LunchBoxCost> days;

  LunchCost get total =>
      days.values.fold(LunchCost.zero, (sum, day) => sum + day.total);

  bool get isAtLeast => days.values.any((day) => day.isAtLeast);

  LunchBoxCost? on(int isoWeekday) => days[isoWeekday];
}

/// The household's school week in money (lunch-box ADR-0007): per box, per
/// child and altogether, and which things have no price yet. Derived from
/// the board and the prices on every emission; nothing here is stored.
@immutable
class LunchWeekCost {
  LunchWeekCost._({
    required List<LunchChildCost> children,
    required Map<String, String> unpricedNames,
  }) : children = List.unmodifiable(children),
       unpricedNames = Map.unmodifiable(unpricedNames);

  factory LunchWeekCost.of({
    required LunchBoard board,
    required Map<String, LunchPrice> prices,
  }) {
    final unpriced = <String, String>{};
    final children = [
      for (final childWeek in board.children)
        LunchChildCost(
          childId: childWeek.childId,
          name: childWeek.child.member.displayName,
          days: {
            for (final day in childWeek.days)
              day.date.weekday: LunchBoxCost.of(day.box, prices),
          },
        ),
    ];
    for (final child in children) {
      for (final day in child.days.values) {
        for (final pick in day.unpriced) {
          unpriced[pick.itemId] =
              board.libraryById[pick.itemId]?.name ?? pick.name;
        }
      }
    }
    return LunchWeekCost._(children: children, unpricedNames: unpriced);
  }

  final List<LunchChildCost> children;

  /// Item id → name, for everything in the week with no price yet.
  final Map<String, String> unpricedNames;

  LunchCost get total =>
      children.fold(LunchCost.zero, (sum, child) => sum + child.total);

  bool get isAtLeast => unpricedNames.isNotEmpty;

  /// Whether anything in the week has a price at all.
  bool get hasPrices => !total.isZero;

  LunchChildCost? childCost(String childId) =>
      children.where((child) => child.childId == childId).firstOrNull;
}
