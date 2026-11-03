import 'package:flutter/foundation.dart';

import '../../../shared/money/money.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';

/// Why a shop's price for an item can be trusted as much as it can
/// (basket-compare ADR-0001 §2).
enum ShopOfferSource {
  /// The member's own pick at this shop, at today's price.
  picked,

  /// The member's own pick, but the shop's search no longer returned it, so
  /// this is the price when it was picked.
  pickedEarlier,

  /// Jev's best match at fit 0.6 or above.
  matched,

  /// Ranking failed, so the shop's first in-stock product stands in.
  closest,
}

enum ShopMissReason { notFound, outOfStock }

/// One shop's answer for one item.
@immutable
sealed class ShopLine {
  const ShopLine(this.shop);

  final ProductRetailer shop;
}

final class ShopOffer extends ShopLine {
  const ShopOffer({
    required ProductRetailer shop,
    required this.name,
    required this.unitPrice,
    required this.packs,
    required this.source,
    this.brand,
    this.imageId,
    this.oldPrice,
    this.isOnPromotion = false,
    this.product,
  }) : super(shop);

  final String name;
  final String? brand;
  final String? imageId;
  final Money unitPrice;
  final Money? oldPrice;
  final bool isOnPromotion;
  final int packs;
  final ShopOfferSource source;

  /// The live product, null for [ShopOfferSource.pickedEarlier]: *Use this
  /// shop* writes it as the item's match.
  final RetailerProduct? product;

  Money get total =>
      Money(unitPrice.cents * packs, currency: unitPrice.currency);
}

final class ShopMiss extends ShopLine {
  const ShopMiss({required ProductRetailer shop, required this.reason})
    : super(shop);

  final ShopMissReason reason;
}

/// The search for this shop failed outright; retrying may answer it.
final class ShopUnreachable extends ShopLine {
  const ShopUnreachable(super.shop);
}

/// One unbought item across the compared shops. A shop not yet in [lines]
/// is still being asked.
@immutable
final class ItemComparison {
  const ItemComparison({
    required this.item,
    required this.packs,
    this.lines = const {},
  });

  final GroceryItem item;
  final int packs;
  final Map<ProductRetailer, ShopLine> lines;

  ItemComparison withLine(ShopLine line) => ItemComparison(
    item: item,
    packs: packs,
    lines: Map.unmodifiable({...lines, line.shop: line}),
  );

  ShopOffer? offerAt(ProductRetailer shop) => switch (lines[shop]) {
    final ShopOffer offer => offer,
    _ => null,
  };

  bool isSettledFor(Iterable<ProductRetailer> shops) =>
      shops.every(lines.containsKey);

  bool isEverywhere(Iterable<ProductRetailer> shops) =>
      shops.every((shop) => offerAt(shop) != null);

  /// The shop with the lowest total among those that have it; null when
  /// fewer than two have it, or two tie for it.
  ProductRetailer? cheapestOf(Iterable<ProductRetailer> shops) {
    final offers = [for (final shop in shops) ?offerAt(shop)];
    if (offers.length < 2) return null;
    offers.sort((a, b) => a.total.compareTo(b.total));
    if (offers[0].total == offers[1].total) return null;
    return offers.first.shop;
  }
}

/// What one shop's basket costs.
@immutable
final class ShopTotal {
  const ShopTotal({
    required this.shop,
    required this.total,
    required this.found,
    required this.missing,
    required this.likeForLike,
  });

  final ProductRetailer shop;

  /// Everything this shop has.
  final Money total;
  final int found;
  final int missing;

  /// Only the items every compared shop has (ADR-0001 §4).
  final Money likeForLike;
}

/// The list's unbought items priced at each compared shop (basket-compare
/// ADR-0001). Fills in as the shops answer; every figure is over the items
/// settled so far.
@immutable
final class BasketComparison {
  const BasketComparison({required this.shops, required this.items});

  final List<ProductRetailer> shops;
  final List<ItemComparison> items;

  int get settledCount =>
      items.where((item) => item.isSettledFor(shops)).length;

  bool get isComplete => settledCount == items.length;

  List<ItemComparison> get _settled => [
    for (final item in items)
      if (item.isSettledFor(shops)) item,
  ];

  /// The settled items every shop has.
  List<ItemComparison> get everywhere => [
    for (final item in _settled)
      if (item.isEverywhere(shops)) item,
  ];

  /// The settled items at least one shop lacks.
  List<ItemComparison> get notEverywhere => [
    for (final item in _settled)
      if (!item.isEverywhere(shops)) item,
  ];

  bool get hasUnreachable => items.any(
    (item) => item.lines.values.any((line) => line is ShopUnreachable),
  );

  List<ShopTotal> get totals {
    final common = everywhere;
    return [
      for (final shop in shops)
        ShopTotal(
          shop: shop,
          total: _sum([for (final item in _settled) item.offerAt(shop)?.total]),
          found: _settled.where((item) => item.offerAt(shop) != null).length,
          missing: _settled.where((item) => item.offerAt(shop) == null).length,
          likeForLike: _sum([
            for (final item in common) item.offerAt(shop)!.total,
          ]),
        ),
    ];
  }

  /// The shop cheapest on the like-for-like basket; null when nothing is at
  /// every shop yet, or the cheapest two tie.
  ShopTotal? get cheapest {
    if (shops.length < 2 || everywhere.isEmpty) return null;
    final ranked = [...totals]
      ..sort((a, b) => a.likeForLike.compareTo(b.likeForLike));
    if (ranked[0].likeForLike == ranked[1].likeForLike) return null;
    return ranked.first;
  }

  /// What [cheapest] saves against the dearest shop on the same items.
  Money get saving {
    final best = cheapest;
    if (best == null) return const Money.zero();
    final dearest = totals
        .map((total) => total.likeForLike)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    return dearest - best.likeForLike;
  }

  /// Each like-for-like item at whichever shop is cheapest for it — a
  /// figure only; NestPrep never splits a cart (ADR-0001 §4).
  Money get splitTotal => _sum([
    for (final item in everywhere)
      [for (final shop in shops) item.offerAt(shop)!.total]
          .reduce((a, b) => a.compareTo(b) <= 0 ? a : b),
  ]);

  static Money _sum(Iterable<Money?> amounts) =>
      amounts.nonNulls.fold(const Money.zero(), (sum, amount) => sum + amount);
}
