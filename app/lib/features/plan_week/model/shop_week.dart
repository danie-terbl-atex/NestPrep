import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';
import '../../family_profiles/model/family_entry.dart';
import '../../lunch_box/model/lunch_basket.dart';
import '../../lunch_box/model/lunch_budget_reading.dart';
import '../../lunch_box/model/lunch_budget_week.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../lunch_box/model/lunch_week_cost.dart';
import 'checked_product.dart';
import 'idea_search.dart';
import 'plan_fallback.dart';
import 'planned_dish.dart';
import 'planned_week_cost.dart';
import 'treat_days.dart';

/// Where one proposed compartment came from, for the week to say.
enum PickOrigin {
  /// The model chose it.
  suggested,

  /// The phone chose it — a week built without AI.
  filled,

  /// A parent swapped it.
  swapped,
}

/// One shop product in one compartment, for the idea it was found for.
@immutable
final class ShopPick {
  const ShopPick({
    required this.ideaId,
    required this.productId,
    required this.origin,
  });

  final String ideaId;
  final String productId;
  final PickOrigin origin;
}

/// One child's week: what is packed already, untouched (lunch-box
/// ADR-0003's rule), and what the plan adds to the empty compartments.
@immutable
final class ShopChildWeek {
  ShopChildWeek({
    required this.child,
    required this.existing,
    required Map<String, ShopPick> added,
  }) : added = Map.unmodifiable(added);

  final FamilyEntry child;
  final LunchPlan existing;

  /// Slot key → what the plan puts there.
  final Map<String, ShopPick> added;

  String get childId => child.memberId;

  ShopPick? addedAt(int day, LunchSlot slot) =>
      added[LunchPlan.slotKey(day, slot)];
}

/// The week the shop's products make (lunch-box ADR-0012, step 4): each
/// chosen child's compartments, the products behind them, how many boxes a
/// pack does, and the basket that adds up to — read against the household's
/// budget. Nothing in it is written until the parent uses it.
@immutable
final class ShopWeek {
  ShopWeek({
    required this.week,
    required this.source,
    required List<ShopChildWeek> children,
    required List<IdeaSearch> searches,
    required Map<String, int> boxesPerPack,
    required Set<int> daysLeft,
    Set<LunchSlot>? slots,
    Set<int>? treatDays,
    this.budget,
    this.weekSoFar,
    this.fallbackReason,
    this.callsLeft,
    this.dropped = 0,
    Map<String, PlannedDish> dishes = const {},
  }) : children = List.unmodifiable(children),
       searches = List.unmodifiable(searches),
       boxesPerPack = Map.unmodifiable(boxesPerPack),
       dishes = Map.unmodifiable(dishes),
       daysLeft = Set.unmodifiable(daysLeft),
       slots = Set.unmodifiable(slots ?? LunchSlot.values),
       treatDays = Set.unmodifiable(treatDays ?? TreatDays.fridayOnly);

  static const packLimit = 100;

  final LunchWeek week;
  final PlanSource source;
  final PlanFallbackReason? fallbackReason;
  final int? callsLeft;

  /// What the server left out as not allowed.
  final int dropped;
  final List<ShopChildWeek> children;

  /// The ideas with what the shop had for them, to swap from.
  final List<IdeaSearch> searches;

  /// Product id → boxes one pack does for every product kept, as the model
  /// reckoned or `LunchPackBoxes` estimated.
  final Map<String, int> boxesPerPack;

  /// The household's weekly lunch budget, when one is set.
  final Money? budget;

  /// Budget mode's picture of the board's week before this plan — what is
  /// packed already, for every child, and the prices behind it — when the
  /// phone had one for this same week.
  final LunchBudgetWeek? weekSoFar;

  /// The school days, by ISO weekday, that have not gone — the only ones
  /// planned or shown (lunch-box ADR-0019; the server's `hasGone`).
  final Set<int> daysLeft;

  /// The compartments the brief fills; the others are left as they are.
  final Set<LunchSlot> slots;

  /// The school days the brief lets a treat go in (lunch-box ADR-0025).
  final Set<int> treatDays;

  /// Idea id → a dish in the week and what it is bought as (lunch-box
  /// ADR-0021).
  final Map<String, PlannedDish> dishes;

  /// Whether the plan may fill [slot] on [day]: a day still to come, a
  /// compartment the brief fills, and a treat only on a treat day.
  bool fills(int day, LunchSlot slot) =>
      daysLeft.contains(day) &&
      slots.contains(slot) &&
      slot.isPlannedOn(day, treatDays);

  int get pickCount =>
      children.fold(0, (total, child) => total + child.added.length);

  bool get isEmpty => pickCount == 0;

  IdeaSearch? searchFor(String ideaId) =>
      searches.where((search) => search.ideaId == ideaId).firstOrNull;

  CheckedProduct? productOf(ShopPick pick) =>
      searchFor(pick.ideaId)?.keptProduct(pick.productId);

  /// The dish [pick] is, when it is one.
  PlannedDish? dishOf(ShopPick pick) =>
      pick.productId == PlannedDish.productIdOf(pick.ideaId)
      ? dishes[pick.ideaId]
      : null;

  /// How many compartments, across every child, hold the dish of [ideaId].
  int boxesOfDish(String ideaId) => [
    for (final child in children)
      for (final pick in child.added.values)
        if (dishOf(pick)?.ideaId == ideaId) pick,
  ].length;

  /// What the grocery list calls a product in the basket: the ingredient it
  /// was bought for, so groceries' own lunch source finds it on the list
  /// (groceries ADR-0006), else the shop's name.
  String shoppingName(String productId) {
    for (final dish in dishes.values) {
      for (final part in dish.parts) {
        if (part.product.productId == productId) return part.ingredient;
      }
    }
    return basketProduct(productId)?.product.name ?? '';
  }

  /// A product in the basket — a kept one, or a dish's ingredient.
  CheckedProduct? basketProduct(String productId) {
    for (final search in searches) {
      if (search.keptProduct(productId) case final kept?) return kept;
    }
    for (final dish in dishes.values) {
      for (final part in dish.parts) {
        if (part.product.productId == productId) return part.product;
      }
    }
    return null;
  }

  int boxesPerPackOf(String productId) => boxesPerPack[productId] ?? 1;

  /// The slot's ideas and the products in them [childId] may have — what a
  /// compartment may be swapped to.
  List<(IdeaSearch, CheckedProduct)> optionsFor(
    String childId,
    LunchSlot slot,
  ) => [
    for (final search in searches)
      if (search.idea.slot == slot)
        for (final product in search.keptFor(childId)) (search, product),
  ];

  /// What [pick] buys: its product, or each of its dish's ingredients.
  List<CheckedProduct> boughtFor(ShopPick pick) => switch (dishOf(pick)) {
    final dish? => [for (final part in dish.parts) part.product],
    null => [?productOf(pick)],
  };

  /// What [child]'s new compartments buy that nothing is known to be in,
  /// offered to them although they have an allergy — each once.
  List<CheckedProduct> labelChecksFor(ShopChildWeek child) => {
    for (final pick in child.added.values)
      for (final product in boughtFor(pick))
        if (product.needsLabelCheckFor(child.childId))
          product.productId: product,
  }.values.toList();

  /// Every new compartment's product — a dish's, each of its ingredients' —
  /// whole packs across every child and every dish that shares one.
  LunchBasket get basket {
    final boxes = <String, int>{};
    final products = <String, CheckedProduct>{};
    for (final child in children) {
      for (final pick in child.added.values) {
        for (final product in boughtFor(pick)) {
          boxes[product.productId] = (boxes[product.productId] ?? 0) + 1;
          products[product.productId] = product;
        }
      }
    }
    return LunchBasket([
      for (final MapEntry(key: productId, value: count) in boxes.entries)
        LunchBasketLine(
          key: productId,
          name: products[productId]!.product.name,
          boxes: count,
          boxesPerPack: boxesPerPackOf(productId),
          packPrice: products[productId]!.product.price,
        ),
    ]);
  }

  /// The household's whole week against its budget — what is packed already
  /// and what this plan adds, in whole packs together, the total the budget
  /// screen will show once it is used (lunch-box ADR-0012 §4) — or null when
  /// no budget is set. Without budget mode's picture of the week, the plan's
  /// basket alone.
  LunchBudgetReading? get reading => switch (budget) {
    null => null,
    final budget => LunchBudgetReading(
      spent: _wholeWeek?.basket.total ?? basket.total,
      budget: budget,
    ),
  };

  /// What the week's priced boxes already cost before this plan, when there
  /// are any.
  Money? get alreadyPlanned => switch (weekSoFar) {
    final week? when week.cost.hasPrices => week.spent,
    _ => null,
  };

  late final LunchWeekCost? _wholeWeek = switch (weekSoFar) {
    final week? => PlannedWeekCost.of(this, week),
    null => null,
  };

  ShopWeek withPick(String childId, String key, ShopPick? pick) => _copy(
    children: [
      for (final child in children)
        if (child.childId == childId)
          ShopChildWeek(
            child: child.child,
            existing: child.existing,
            added: {
              for (final entry in child.added.entries)
                if (entry.key != key) entry.key: entry.value,
              key: ?pick,
            },
          )
        else
          child,
    ],
  );

  /// [pick] in [slot] on every day the plan holds it for [childId] — and
  /// for every other child whose [slot] held the same product on [day] and
  /// who may have [pick] — so a week is swapped in one go (lunch-box
  /// ADR-0028 §6). Null empties those days.
  ShopWeek withPickEveryDay(
    String childId,
    int day,
    LunchSlot slot,
    ShopPick? pick,
  ) {
    final was = children
        .where((child) => child.childId == childId)
        .firstOrNull
        ?.addedAt(day, slot);
    bool shares(ShopChildWeek child) =>
        child.childId == childId ||
        (was != null &&
            child.addedAt(day, slot)?.productId == was.productId &&
            (pick == null || _mayHave(child.childId, pick)));
    return _copy(
      children: [
        for (final child in children)
          if (shares(child))
            ShopChildWeek(
              child: child.child,
              existing: child.existing,
              added: {
                for (final entry in child.added.entries)
                  if (!entry.key.endsWith('_${slot.name}'))
                    entry.key: entry.value,
                for (var each = 1; each <= LunchWeek.schoolDayCount; each++)
                  if (child.addedAt(each, slot) != null ||
                      (child.childId == childId && each == day))
                    LunchPlan.slotKey(each, slot): ?pick,
              },
            )
          else
            child,
      ],
    );
  }

  bool _mayHave(String childId, ShopPick pick) => dishOf(pick) == null
      ? productOf(pick)?.childIds.contains(childId) ?? false
      : searchFor(pick.ideaId)?.dishChildIds.contains(childId) ?? false;

  ShopWeek _copy({List<ShopChildWeek>? children}) => ShopWeek(
    week: week,
    source: source,
    fallbackReason: fallbackReason,
    callsLeft: callsLeft,
    dropped: dropped,
    children: children ?? this.children,
    searches: searches,
    boxesPerPack: boxesPerPack,
    daysLeft: daysLeft,
    slots: slots,
    treatDays: treatDays,
    budget: budget,
    weekSoFar: weekSoFar,
    dishes: dishes,
  );
}
