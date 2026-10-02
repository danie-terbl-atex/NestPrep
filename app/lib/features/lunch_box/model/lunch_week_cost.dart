import 'package:flutter/foundation.dart';

import 'lunch_basket.dart';
import 'lunch_board.dart';
import 'lunch_price.dart';

/// The household's school week in money (lunch-box ADR-0007, measured as
/// ADR-0012 §4 says): every child's boxes together, each priced thing's
/// boxes rounded up to the whole packs the till sells, and which things have
/// no price yet. Derived from the board and the prices on every emission;
/// nothing here is stored.
@immutable
class LunchWeekCost {
  LunchWeekCost._({
    required this.basket,
    required Map<String, String> unpricedNames,
  }) : unpricedNames = Map.unmodifiable(unpricedNames);

  factory LunchWeekCost.of({
    required LunchBoard board,
    required Map<String, LunchPrice> prices,
  }) {
    final boxes = <String, int>{};
    final names = <String, String>{};
    for (final childWeek in board.children) {
      for (final day in childWeek.days) {
        for (final (_, pick) in day.box.filled) {
          boxes[pick.itemId] = (boxes[pick.itemId] ?? 0) + 1;
          names[pick.itemId] =
              board.libraryById[pick.itemId]?.name ?? pick.name;
        }
      }
    }
    return LunchWeekCost._(
      basket: LunchBasket([
        for (final MapEntry(key: itemId, value: count) in boxes.entries)
          if (prices[itemId] case final price?)
            LunchBasketLine(
              key: itemId,
              name: names[itemId] ?? itemId,
              boxes: count,
              boxesPerPack: price.portions,
              packPrice: price.money,
            ),
      ]),
      unpricedNames: {
        for (final itemId in boxes.keys)
          if (!prices.containsKey(itemId)) itemId: names[itemId] ?? itemId,
      },
    );
  }

  /// What the week's priced things cost at the till, whole packs.
  final LunchBasket basket;

  /// Item id → name, for everything in the week with no price yet.
  final Map<String, String> unpricedNames;

  /// A total with an unpriced thing in it is *at least* that much.
  bool get isAtLeast => unpricedNames.isNotEmpty;

  /// Whether anything in the week has a price at all.
  bool get hasPrices => !basket.isEmpty;
}
