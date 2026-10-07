import '../../../shared/money/money.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'checked_product.dart';
import 'idea_search.dart';
import 'lunch_week_reply.dart';
import 'plan_fallback.dart';
import 'shop_week.dart';

/// Builds the week the review shows from what the phone holds now
/// (lunch-box ADR-0012, step 4): the model's answer checked once more — a
/// product the phone kept for that child, for an idea in that slot, in a
/// compartment still empty and one the brief fills, a treat on Friday only —
/// or, without AI, a week the phone makes itself from the same products and
/// says so.
///
/// It never touches a compartment somebody already filled.
abstract final class ShopWeekAssembly {
  static ShopWeek fromReply({
    required LunchBoard board,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required LunchWeekReply reply,
    required Money? budget,
    required Set<LunchSlot> slots,
  }) {
    final byIdea = {for (final search in searches) search.ideaId: search};
    var result = _empty(
      board,
      childIds,
      searches,
      budget,
      slots,
      PlanSource.ai,
    );
    final used = <String>{};
    for (final lunch in reply.lunches) {
      final child = board.childWeek(lunch.childId);
      final search = byIdea[lunch.ideaId];
      final product = search?.keptProduct(lunch.productId);
      final key = LunchPlan.slotKey(lunch.day, lunch.slot);
      final isOpen =
          child != null &&
          childIds.contains(lunch.childId) &&
          !child.plan.slots.containsKey(key) &&
          used.add('${lunch.childId}/$key');
      if (!isOpen ||
          search == null ||
          product == null ||
          search.idea.slot != lunch.slot ||
          !slots.contains(lunch.slot) ||
          !lunch.slot.isAutoFilledOn(lunch.day) ||
          !product.childIds.contains(lunch.childId)) {
        continue;
      }
      result = result.withPick(
        lunch.childId,
        key,
        ShopPick(
          ideaId: search.ideaId,
          productId: product.productId,
          origin: PickOrigin.suggested,
        ),
      );
    }
    return ShopWeek(
      week: board.week,
      source: PlanSource.ai,
      children: result.children,
      searches: searches,
      boxesPerPack: _packs(result, reply.boxesPerPack),
      slots: slots,
      budget: budget,
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
    required Set<LunchSlot> slots,
    required PlanFallbackReason reason,
  }) {
    var result = _empty(
      board,
      childIds,
      searches,
      budget,
      slots,
      PlanSource.fallback,
    );
    for (final child in result.children) {
      for (var day = 1; day <= 5; day++) {
        for (final slot in LunchSlot.values.where(slots.contains)) {
          final key = LunchPlan.slotKey(day, slot);
          if (!slot.isAutoFilledOn(day) ||
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
      slots: slots,
      budget: budget,
    );
  }

  static ShopWeek _empty(
    LunchBoard board,
    Set<String> childIds,
    List<IdeaSearch> searches,
    Money? budget,
    Set<LunchSlot> slots,
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
    slots: slots,
    budget: budget,
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
