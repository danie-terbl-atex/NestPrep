import 'dart:math';

import '../../../shared/money/money.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_budget_week.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_variety.dart';
import 'checked_product.dart';
import 'idea_search.dart';
import 'lunch_pack_boxes.dart';
import 'lunch_week_reply.dart';
import 'packing_preference.dart';
import 'plan_fallback.dart';
import 'planned_dish.dart';
import 'shop_week.dart';

/// Builds the week the review shows from what the phone holds now
/// (lunch-box ADR-0012, step 4): the model's answer checked once more — a
/// product the phone kept for that child, for an idea in that slot, in a
/// compartment still empty and one the brief fills, on a school day that
/// has not gone, a treat only on one of the brief's treat days (ADR-0025) —
/// or, without AI, a week the phone makes itself from the same products and
/// says so. A dish (ADR-0021) goes in only from the server's week, for a
/// child its idea is still for; a phone-built week has no dishes.
///
/// It never touches a compartment somebody already filled.
abstract final class ShopWeekAssembly {
  /// Kinds a varying compartment takes a week without AI, as the server's
  /// `MAX_KINDS` (foundation ADR-0023).
  static const mostKinds = 3;

  static ShopWeek fromReply({
    required LunchBoard board,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required LunchWeekReply reply,
    required Money? budget,
    required PackingChoice packing,
    LunchBudgetWeek? weekSoFar,
  }) {
    final byIdea = {for (final search in searches) search.ideaId: search};
    final dishes = _dishes(reply, byIdea);
    var result = _empty(board, childIds, searches, packing, PlanSource.ai);
    final used = <String>{};
    for (final lunch in reply.lunches) {
      final child = board.childWeek(lunch.childId);
      final search = byIdea[lunch.ideaId];
      final dish = dishes[lunch.ideaId];
      final mayHave = dish != null && lunch.productId == dish.productId
          ? search!.dishChildIds.contains(lunch.childId)
          : search
                    ?.keptProduct(lunch.productId)
                    ?.childIds
                    .contains(lunch.childId) ??
                false;
      final key = LunchPlan.slotKey(lunch.day, lunch.slot);
      final isOpen =
          child != null &&
          childIds.contains(lunch.childId) &&
          !child.plan.slots.containsKey(key) &&
          used.add('${lunch.childId}/$key');
      if (!isOpen ||
          search == null ||
          !mayHave ||
          search.idea.slot != lunch.slot ||
          !result.fills(lunch.day, lunch.slot)) {
        continue;
      }
      result = result.withPick(
        lunch.childId,
        key,
        ShopPick(
          ideaId: search.ideaId,
          productId: lunch.productId,
          origin: PickOrigin.suggested,
        ),
      );
    }
    return ShopWeek(
      week: board.week,
      source: PlanSource.ai,
      children: result.children,
      searches: searches,
      dishes: dishes,
      boxesPerPack: {
        ..._packs(searches, reply.boxesPerPack),
        for (final dish in dishes.values)
          for (final part in dish.parts)
            part.product.productId:
                (reply.boxesPerPack[part.product.productId] ??
                        part.product.product.packCount ??
                        1)
                    .clamp(1, ShopWeek.packLimit),
      },
      daysLeft: result.daysLeft,
      slots: packing.slots,
      treatDays: packing.treatDays,
      budget: budget,
      weekSoFar: _sameWeek(weekSoFar, board),
      callsLeft: reply.callsLeft,
      dropped: reply.dropped,
    );
  }

  /// A week made on the phone: for each empty compartment the brief fills,
  /// the slot's first idea every day when [variety] keeps it the same all
  /// week, else up to [mostKinds] of its ideas in turn — and from the idea
  /// the product that costs least a box (lunch-box ADR-0028). Children who
  /// may have the same things get the same box, so it is packed once.
  static ShopWeek fallback({
    required LunchBoard board,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required Money? budget,
    required PackingChoice packing,
    required PlanFallbackReason reason,
    LunchVariety variety = LunchVariety.standard,
    LunchBudgetWeek? weekSoFar,
  }) {
    var result = _empty(
      board,
      childIds,
      searches,
      packing,
      PlanSource.fallback,
    );
    for (final child in result.children) {
      final childWeek = board.childWeek(child.childId);
      for (var day = 1; day <= 5; day++) {
        if (childWeek == null) continue;
        for (final slot in LunchSlot.values) {
          final key = LunchPlan.slotKey(day, slot);
          if (!result.fills(day, slot) ||
              child.existing.slots.containsKey(key)) {
            continue;
          }
          final ideas = [
            for (final search in searches)
              if (search.idea.slot == slot &&
                  search.keptFor(child.childId).isNotEmpty)
                search,
          ];
          if (ideas.isEmpty) continue;
          final search = variety.keepsSame(slot)
              ? ideas.first
              : ideas[(day - 1) % min(ideas.length, mostKinds)];
          final product = _cheapest(search.keptFor(child.childId), slot);
          result = result.withPick(
            child.childId,
            key,
            ShopPick(
              ideaId: search.ideaId,
              productId: product.productId,
              origin: PickOrigin.filled,
            ),
          );
        }
      }
    }
    return ShopWeek(
      week: board.week,
      source: PlanSource.fallback,
      fallbackReason: reason,
      children: result.children,
      searches: searches,
      boxesPerPack: _packs(searches, const {}),
      daysLeft: result.daysLeft,
      slots: packing.slots,
      treatDays: packing.treatDays,
      budget: budget,
      weekSoFar: _sameWeek(weekSoFar, board),
    );
  }

  /// Each dish the server placed (lunch-box ADR-0021 §4), with the products
  /// it is bought as — only ones this phone found for that ingredient.
  static Map<String, PlannedDish> _dishes(
    LunchWeekReply reply,
    Map<String, IdeaSearch> byIdea,
  ) => {
    for (final MapEntry(key: ideaId, value: parts) in reply.dishes.entries)
      if (byIdea[ideaId] case final search?)
        if (search.idea.dish case final draft?)
          ideaId: PlannedDish(
            ideaId: ideaId,
            draft: draft,
            parts: [
              for (final part in parts)
                if (search.ingredientProduct(part.productId) case final p?)
                  (ingredient: part.ingredient, product: p),
            ],
          ),
  };

  /// Budget mode's week only when it is the week being planned.
  static LunchBudgetWeek? _sameWeek(LunchBudgetWeek? week, LunchBoard board) =>
      week != null && week.board.week == board.week ? week : null;

  static ShopWeek _empty(
    LunchBoard board,
    Set<String> childIds,
    List<IdeaSearch> searches,
    PackingChoice packing,
    PlanSource source,
  ) => ShopWeek(
    week: board.week,
    source: source,
    children: [
      for (final childWeek in board.children)
        if (childIds.contains(childWeek.childId))
          ShopChildWeek(
            child: childWeek.child,
            existing: childWeek.plan,
            added: const {},
          ),
    ],
    searches: searches,
    boxesPerPack: const {},
    daysLeft: board.week.daysLeftAfter(board.today),
    slots: packing.slots,
    treatDays: packing.treatDays,
  );

  /// Boxes a pack does for every product kept — not only the placed ones,
  /// so a swap is priced at its real pack: the model's, else
  /// [LunchPackBoxes.of].
  static Map<String, int> _packs(
    List<IdeaSearch> searches,
    Map<String, int> reckoned,
  ) => {
    for (final search in searches)
      for (final kept in search.kept)
        kept.productId:
            (reckoned[kept.productId] ??
                    LunchPackBoxes.of(kept.product, search.idea.slot))
                .clamp(1, ShopWeek.packLimit),
  };

  /// The product that costs least a box, by [LunchPackBoxes.of] — compared
  /// without division, in whole cents.
  static CheckedProduct _cheapest(
    List<CheckedProduct> products,
    LunchSlot slot,
  ) => products.reduce((best, next) {
    final bestCount = LunchPackBoxes.of(best.product, slot);
    final nextCount = LunchPackBoxes.of(next.product, slot);
    return next.product.price.cents * bestCount <
            best.product.price.cents * nextCount
        ? next
        : best;
  });
}
