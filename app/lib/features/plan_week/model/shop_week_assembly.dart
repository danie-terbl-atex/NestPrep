import '../../../shared/money/money.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_budget_week.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'checked_product.dart';
import 'idea_search.dart';
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
          _hasGone(child, lunch.day) ||
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
        ..._packs(result, reply.boxesPerPack),
        for (final dish in dishes.values)
          for (final part in dish.parts)
            part.product.productId:
                (reply.boxesPerPack[part.product.productId] ??
                        part.product.product.packCount ??
                        1)
                    .clamp(1, ShopWeek.packLimit),
      },
      slots: packing.slots,
      treatDays: packing.treatDays,
      budget: budget,
      weekSoFar: _sameWeek(weekSoFar, board),
      callsLeft: reply.callsLeft,
      dropped: reply.dropped,
    );
  }

  /// A week made on the phone: for each empty compartment the brief fills,
  /// the slot's ideas taken in turn — moved on a place each day, so the week
  /// varies — and from the idea the product that costs least a box. Children
  /// who may have the same things get the same box, so it is packed once.
  static ShopWeek fallback({
    required LunchBoard board,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required Money? budget,
    required PackingChoice packing,
    required PlanFallbackReason reason,
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
        if (childWeek == null || _hasGone(childWeek, day)) continue;
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
          final search = ideas[(day - 1) % ideas.length];
          final product = _cheapest(search.keptFor(child.childId));
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
      boxesPerPack: _packs(result, const {}),
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

  /// A school day the board says has happened — today or earlier — is
  /// never planned (lunch-box ADR-0019; the server's `hasGone`).
  static bool _hasGone(LunchChildWeek childWeek, int day) =>
      childWeek.dayOn(day)?.hasHappened ?? true;

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
    slots: packing.slots,
    treatDays: packing.treatDays,
  );

  /// Boxes a pack does for every product in the week: the model's, else
  /// what the shop says a pack holds, else one.
  static Map<String, int> _packs(ShopWeek week, Map<String, int> reckoned) => {
    for (final child in week.children)
      for (final pick in child.added.values)
        pick.productId:
            (reckoned[pick.productId] ??
                    week.productOf(pick)?.product.packCount ??
                    1)
                .clamp(1, ShopWeek.packLimit),
  };

  /// The product that costs least a box, by its pack count when the shop
  /// gave one — compared without division, in whole cents.
  static CheckedProduct _cheapest(List<CheckedProduct> products) =>
      products.reduce((best, next) {
        final bestCount = best.product.packCount ?? 1;
        final nextCount = next.product.packCount ?? 1;
        return next.product.price.cents * bestCount <
                best.product.price.cents * nextCount
            ? next
            : best;
      });
}
