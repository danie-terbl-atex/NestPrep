import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/model/retailer_product.dart';

/// Where one ingredient's search at the shop has got to.
enum RecipeShopSearch { waiting, searching, found, notFound, failed }

/// One ingredient a planned recipe still needs, as *Add to grocer* found it
/// at the shop (recipes ADR-0005): what to call it on the grocery list and
/// how much, the products the shop answered, the one chosen to buy, and
/// whether it goes on the list at all.
@immutable
final class RecipeShopLine {
  const RecipeShopLine({
    required this.index,
    required this.name,
    required this.quantity,
    this.search = RecipeShopSearch.waiting,
    this.products = const [],
    this.chosen,
    this.isBestMatch = false,
    this.failure,
    this.isIncluded = true,
  });

  /// Its place in the recipe's own ingredient list.
  final int index;
  final String name;

  /// The grocery list's words for how much ("1.5 kg", "2 tins") — null for
  /// a kitchen measure, which a shop does not sell by (groceries ADR-0003).
  final String? quantity;
  final RecipeShopSearch search;

  /// Everything the shop answered, to swap between.
  final List<RetailerProduct> products;

  /// The product to buy — null when nothing buyable was found, and the line
  /// goes on the list unmatched.
  final RetailerProduct? chosen;

  /// [chosen] is the one Jev ranked best, not just the shop's first.
  final bool isBestMatch;
  final AppFailure? failure;
  final bool isIncluded;

  bool get isSettled => switch (search) {
    RecipeShopSearch.waiting || RecipeShopSearch.searching => false,
    _ => true,
  };

  RecipeShopLine searching() => _copy(search: RecipeShopSearch.searching);

  /// [products] in the order to offer them; [best] — Jev's pick, or null —
  /// is chosen when it can be bought, else the first that can.
  RecipeShopLine found(List<RetailerProduct> products, {String? best}) {
    final buyable = products.where(isBuyable).toList();
    final ranked = best == null
        ? null
        : buyable.where((product) => product.id == best).firstOrNull;
    final chosen = ranked ?? buyable.firstOrNull;
    return RecipeShopLine(
      index: index,
      name: name,
      quantity: quantity,
      search: chosen == null
          ? RecipeShopSearch.notFound
          : RecipeShopSearch.found,
      products: List.unmodifiable(products),
      chosen: chosen,
      isBestMatch: ranked != null,
      isIncluded: isIncluded,
    );
  }

  RecipeShopLine failedWith(AppFailure failure) => RecipeShopLine(
    index: index,
    name: name,
    quantity: quantity,
    search: RecipeShopSearch.failed,
    failure: failure,
    isIncluded: isIncluded,
  );

  RecipeShopLine choosing(RetailerProduct product) => RecipeShopLine(
    index: index,
    name: name,
    quantity: quantity,
    search: RecipeShopSearch.found,
    products: products,
    chosen: product,
    isIncluded: isIncluded,
  );

  RecipeShopLine toggled() => _copy(isIncluded: !isIncluded);

  /// A product a cart can take as it is: in stock, and sold by the pack —
  /// one sold by weight needs a weight chosen (lunch-box ADR-0012).
  static bool isBuyable(RetailerProduct product) =>
      product.isInStock && !product.isSoldByWeight;

  RecipeShopLine _copy({RecipeShopSearch? search, bool? isIncluded}) =>
      RecipeShopLine(
        index: index,
        name: name,
        quantity: quantity,
        search: search ?? this.search,
        products: products,
        chosen: chosen,
        isBestMatch: isBestMatch,
        failure: failure,
        isIncluded: isIncluded ?? this.isIncluded,
      );
}
