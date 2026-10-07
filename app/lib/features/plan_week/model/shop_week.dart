import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';
import '../../family_profiles/model/family_entry.dart';
import '../../lunch_box/model/lunch_basket.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import 'checked_product.dart';
import 'idea_search.dart';
import 'plan_fallback.dart';

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
    Set<LunchSlot>? slots,
    this.budget,
    this.fallbackReason,
    this.callsLeft,
    this.dropped = 0,
  }) : children = List.unmodifiable(children),
       searches = List.unmodifiable(searches),
       boxesPerPack = Map.unmodifiable(boxesPerPack),
       slots = Set.unmodifiable(slots ?? LunchSlot.values);

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

  /// Product id → boxes one pack does, as the model reckoned or the parent
  /// corrected.
  final Map<String, int> boxesPerPack;

  /// The household's weekly lunch budget, when one is set.
  final Money? budget;

  /// The compartments the brief fills; the others are left as they are.
  final Set<LunchSlot> slots;

  int get pickCount =>
      children.fold(0, (total, child) => total + child.added.length);

  bool get isEmpty => pickCount == 0;

  IdeaSearch? searchFor(String ideaId) =>
      searches.where((search) => search.ideaId == ideaId).firstOrNull;

  CheckedProduct? productOf(ShopPick pick) =>
      searchFor(pick.ideaId)?.keptProduct(pick.productId);

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

  /// Every new compartment's product, whole packs across every child.
  LunchBasket get basket {
    final boxes = <String, int>{};
    final products = <String, CheckedProduct>{};
    for (final child in children) {
      for (final pick in child.added.values) {
        final product = productOf(pick);
        if (product == null) continue;
        boxes[pick.productId] = (boxes[pick.productId] ?? 0) + 1;
        products[pick.productId] = product;
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

  ShopWeek _copy({List<ShopChildWeek>? children}) => ShopWeek(
    week: week,
    source: source,
    fallbackReason: fallbackReason,
    callsLeft: callsLeft,
    dropped: dropped,
    children: children ?? this.children,
    searches: searches,
    boxesPerPack: boxesPerPack,
    slots: slots,
    budget: budget,
  );
}
