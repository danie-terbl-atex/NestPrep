import '../../lunch_box/model/lunch_budget_week.dart';
import '../../lunch_box/model/lunch_price.dart';
import '../../lunch_box/model/lunch_week_cost.dart';
import 'shop_product_item.dart';
import 'shop_week.dart';

/// What the budget screen will read once a plan is used (lunch-box
/// ADR-0012 §4, ADR-0019): every box already packed in the board's week, for
/// every child, and every compartment the plan adds — each as the library
/// item *Use it* makes it (`shopProductItem`, the board's own when it holds
/// one like it), at the shelf price *Use it* writes over the item's — priced
/// by the same `LunchWeekCost` as the meter, so the two read the same total.
///
/// A dish (ADR-0021 §5) is its own item, priced as what its ingredient packs
/// cost for the boxes the plan packs of it — exactly what *Use it* writes.
abstract final class PlannedWeekCost {
  static LunchWeekCost of(ShopWeek plan, LunchBudgetWeek weekSoFar) {
    final board = weekSoFar.board;
    final prices = <String, LunchPrice>{...weekSoFar.prices};
    final itemByProduct = <String, ({String itemId, String name})>{};
    final added = <({String itemId, String name})>[];
    for (final child in plan.children) {
      for (final pick in child.added.values) {
        final slot = plan.searchFor(pick.ideaId)?.idea.slot;
        if (slot == null) continue;
        if (plan.dishOf(pick) case final dish?) {
          final item = itemByProduct.putIfAbsent(dish.productId, () {
            final boxes = plan.boxesOfDish(dish.ideaId);
            final itemId = 'shop:${dish.productId}';
            _price(
              prices,
              itemId,
              cents: dish.costFor(boxes, plan.boxesPerPackOf).cents,
              portions: boxes,
            );
            return (itemId: itemId, name: dish.draft.name);
          });
          added.add(item);
          continue;
        }
        final product = plan.productOf(pick);
        if (product == null) continue;
        final item = itemByProduct.putIfAbsent(
          '${pick.productId}/${slot.name}',
          () {
            final candidate = shopProductItem(product, slot, addedBy: '');
            final known = board.itemLike(candidate);
            final itemId = known?.id ?? 'shop:${pick.productId}/${slot.name}';
            _price(
              prices,
              itemId,
              cents: product.product.price.cents,
              portions: plan.boxesPerPackOf(pick.productId),
            );
            return (itemId: itemId, name: known?.name ?? candidate.name);
          },
        );
        added.add(item);
      }
    }
    return LunchWeekCost.of(board: board, prices: prices, alsoPacked: added);
  }

  /// As the saver: a price the rules would refuse is not written.
  static void _price(
    Map<String, LunchPrice> prices,
    String itemId, {
    required int cents,
    required int portions,
  }) {
    if (cents < 0 ||
        cents > LunchPrice.centsLimit ||
        portions < 1 ||
        portions > LunchPrice.portionLimit) {
      return;
    }
    prices[itemId] = LunchPrice(
      id: itemId,
      cents: cents,
      portions: portions,
      updatedBy: '',
    );
  }
}
