import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/text/normalised_name.dart';
import '../../lunch_box/data/lunch_budget_repository.dart';
import '../../lunch_box/data/lunch_repository.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_pick.dart';
import '../../lunch_box/model/lunch_price.dart';
import '../../lunch_box/model/lunch_safety.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../model/checked_product.dart';
import '../model/shop_week.dart';

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
final class ShopWeekSaver {
  ShopWeekSaver({
    required LunchRepository lunchRepository,
    required LunchBudgetRepository budgetRepository,
    required this.householdId,
    required this.memberId,
  }) : _lunches = lunchRepository,
       _budget = budgetRepository;

  final LunchRepository _lunches;
  final LunchBudgetRepository _budget;
  final String householdId;
  final String memberId;

  Future<ShopWeekSaved> save(ShopWeek plan, {required LunchBoard board}) async {
    final picksByProduct = <String, LunchPick>{};
    var pricesSaved = true;
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

    var lunches = 0;
    var skipped = 0;
    for (final planned in plan.children) {
      final now = board.childWeek(planned.childId);
      if (now == null) {
        skipped += planned.added.length;
        continue;
      }
      final picks = <String, LunchPick>{};
      for (final MapEntry(:key, value: shopPick) in planned.added.entries) {
        final slot = plan.searchFor(shopPick.ideaId)?.idea.slot;
        final pick = picksByProduct['${shopPick.productId}/${slot?.name}'];
        final isSafe =
            pick != null &&
            LunchSafety.isSafe(
              allergens: pick.knownAllergens,
              rules: now.child.foodRules,
            );
        if (now.plan.slots.containsKey(key) || !isSafe) {
          skipped++;
        } else {
          picks[key] = pick;
        }
      }
      if (picks.isEmpty) continue;
      try {
        await _lunches.setPicks(
          householdId: householdId,
          childId: planned.childId,
          week: plan.week,
          picks: picks,
        );
        lunches += picks.length;
      } on PermissionDeniedFailure {
        // The rules said no — the child's rules changed on another phone.
        // The other children's weeks still go in.
        skipped += picks.length;
      }
    }
    return ShopWeekSaved(
      lunches: lunches,
      skipped: skipped,
      pricesSaved: pricesSaved,
    );
  }

  Future<LunchItem> _itemFor(
    CheckedProduct product,
    LunchSlot slot,
    LunchBoard board,
  ) async {
    final name = _cut(product.product.name.trim(), LunchItem.nameLimit);
    final key = normalisedName(name);
    final known = board.library
        .where((item) => !item.archived && item.slot == slot)
        .where((item) => item.nameKey == key)
        .firstOrNull;
    if (known != null) return known;
    final item = LunchItem.named(
      id: '',
      name: name,
      slot: slot,
      allergens: product.allergens,
      addedBy: memberId,
    );
    final id = await _lunches.addItem(householdId, item);
    return item.copyWith(id: id);
  }

  /// The shelf price for a pack of so many boxes; false when it was refused.
  Future<bool> _price(
    String itemId,
    CheckedProduct product,
    ShopWeek plan,
  ) async {
    final cents = product.product.price.cents;
    if (cents < 0 || cents > LunchPrice.centsLimit) return true;
    try {
      await _budget.setPrice(
        householdId,
        LunchPrice(
          id: itemId,
          cents: cents,
          portions: plan.boxesPerPackOf(product.productId),
          updatedBy: memberId,
        ),
      );
      return true;
    } on PermissionDeniedFailure {
      return false;
    }
  }

  static String _cut(String text, int longest) =>
      text.length <= longest ? text : text.substring(0, longest).trim();
}
