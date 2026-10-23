import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../lunch_box/data/lunch_budget_repository.dart';
import '../../lunch_box/data/lunch_repository.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_pick.dart';
import '../../lunch_box/model/lunch_price.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/state/lunch_library_items.dart';
import '../../lunch_box/state/week_picks_writer.dart';
import '../data/lunch_recipe_saver.dart';
import '../model/checked_product.dart';
import '../model/planned_dish.dart';
import '../model/shop_product_item.dart';
import '../model/shop_week.dart';
import 'shop_dish_items.dart';

/// What using a week wrote.
@immutable
final class ShopWeekSaved {
  const ShopWeekSaved({
    required this.lunches,
    required this.skipped,
    required this.pricesSaved,
  });

  /// Compartments packed, across every child.
  final int lunches;

  /// Proposed compartments not written: filled by somebody else meanwhile,
  /// no longer safe for the child, or refused by the rules.
  final int skipped;

  /// False when the rules refused the prices (premium lapsed meanwhile); the
  /// lunches went in anyway.
  final bool pricesSaved;
}

/// Writes a week a parent chose to use (lunch-box ADR-0012 §3): each shop
/// product becomes — or reuses, by name in the same slot — a library item
/// carrying the allergens its words name, its shelf price is written as the
/// item's price for a pack of so many boxes, and the compartments go in
/// through the same repository and rules as packing a box by hand. A pick
/// carries every code the library item or the shop's words name, so the
/// rules check the stricter of the two (lunch-box ADR-0001), and a week
/// write still carries one school day (ADR-0010, inside `setPicks`).
///
/// A dish (ADR-0021 §5) is saved first — its recipe, then its item — and
/// priced as its ingredient packs for the boxes it fills.
final class ShopWeekSaver {
  ShopWeekSaver({
    required LunchRepository lunchRepository,
    required LunchBudgetRepository budgetRepository,
    required LunchRecipeSaver recipeSaver,
    required this.householdId,
    required this.memberId,
  }) : _budget = budgetRepository,
       _library = LunchLibraryItems(
         lunchRepository: lunchRepository,
         householdId: householdId,
       ),
       _writer = WeekPicksWriter(
         lunchRepository: lunchRepository,
         householdId: householdId,
       ) {
    _dishes = ShopDishItems(
      recipes: recipeSaver,
      library: _library,
      householdId: householdId,
      memberId: memberId,
    );
  }

  final LunchBudgetRepository _budget;
  final LunchLibraryItems _library;
  final WeekPicksWriter _writer;
  late final ShopDishItems _dishes;
  final String householdId;
  final String memberId;

  Future<ShopWeekSaved> save(ShopWeek plan, {required LunchBoard board}) async {
    final picksByProduct = <String, LunchPick>{};
    var pricesSaved = true;
    // Dishes first: their recipes, then their items (lunch-box ADR-0021 §5).
    for (final MapEntry(key: ideaId, value: dish) in (await _dishes.save(
      plan,
      board,
    )).entries) {
      picksByProduct['${PlannedDish.productIdOf(ideaId)}/${LunchSlot.main.name}'] =
          LunchPick(
            itemId: dish.item.id,
            name: dish.item.name,
            allergens: dish.item.allergens,
          );
      pricesSaved &= await _setPrice(
        dish.item.id,
        cents: dish.cents,
        portions: dish.boxes,
      );
    }
    for (final child in plan.children) {
      for (final pick in child.added.values) {
        final product = plan.productOf(pick);
        final slot = plan.searchFor(pick.ideaId)?.idea.slot;
        if (product == null || slot == null) continue;
        final key = '${pick.productId}/${slot.name}';
        if (picksByProduct.containsKey(key)) continue;
        final item = await _itemFor(product, slot, board);
        picksByProduct[key] = LunchPick(
          itemId: item.id,
          name: item.name,
          allergens: {
            ...item.allergens,
            for (final allergen in product.allergens) allergen.name,
          }.toList(),
        );
        pricesSaved &= await _price(item.id, product, plan);
      }
    }

    var unresolved = 0;
    final picksByChild = <String, Map<String, LunchPick>>{};
    for (final planned in plan.children) {
      for (final MapEntry(:key, value: shopPick) in planned.added.entries) {
        final slot = plan.searchFor(shopPick.ideaId)?.idea.slot;
        final pick = picksByProduct['${shopPick.productId}/${slot?.name}'];
        if (pick == null) {
          unresolved++;
        } else {
          (picksByChild[planned.childId] ??= {})[key] = pick;
        }
      }
    }
    final written = await _writer.write(
      board: board,
      week: plan.week,
      picksByChild: picksByChild,
    );
    return ShopWeekSaved(
      lunches: written.lunches,
      skipped: written.skipped + unresolved,
      pricesSaved: pricesSaved,
    );
  }

  Future<LunchItem> _itemFor(
    CheckedProduct product,
    LunchSlot slot,
    LunchBoard board,
  ) =>
      _library.ensure(shopProductItem(product, slot, addedBy: memberId), board);

  /// The shelf price for a pack of so many boxes.
  Future<bool> _price(String itemId, CheckedProduct product, ShopWeek plan) =>
      _setPrice(
        itemId,
        cents: product.product.price.cents,
        portions: plan.boxesPerPackOf(product.productId),
      );

  /// [cents] for [portions] boxes; false when the rules refused it. A price
  /// they would refuse anyway is not sent.
  Future<bool> _setPrice(
    String itemId, {
    required int cents,
    required int portions,
  }) async {
    if (cents < 0 ||
        cents > LunchPrice.centsLimit ||
        portions < 1 ||
        portions > LunchPrice.portionLimit) {
      return true;
    }
    try {
      await _budget.setPrice(
        householdId,
        LunchPrice(
          id: itemId,
          cents: cents,
          portions: portions,
          updatedBy: memberId,
        ),
      );
      return true;
    } on PermissionDeniedFailure {
      return false;
    }
  }
}
