import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../add_to_checkers/data/checkers_place_resolver.dart';
import '../../add_to_checkers/data/product_match_ranker.dart';
import '../../add_to_checkers/data/retailer_catalogues.dart';
import '../../add_to_checkers/model/checkers_place.dart';
import '../../add_to_checkers/model/product_match_from.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../add_to_checkers/state/product_match_controller.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../../plan_week/model/packs_in_quantity.dart';
import '../model/basket_comparison.dart';

/// *Compare shops* (basket-compare ADR-0001): the list's unbought items asked
/// at every compared shop, the shops in parallel and each a few searches at a
/// time, filling in as the answers land. Nothing is stored until somebody
/// taps *Use this shop*, which writes that shop's products as the items'
/// matches.
final class BasketCompareController extends ChangeNotifier
    with ActionFailureHolder {
  BasketCompareController({
    required this._catalogues,
    required CheckersPlaceResolver placeResolver,
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this._memberId,
    required this.shops,
    this._ranker,
  }) : _places = placeResolver,
       _repository = groceryRepository;

  static const itemLimit = 40;
  static const searchesPerShop = 3;

  final RetailerCatalogues _catalogues;
  final ProductMatchRanker? _ranker;
  final CheckersPlaceResolver _places;
  final GroceryRepository _repository;
  final String householdId;
  final String _memberId;
  final List<ProductRetailer> shops;

  AsyncState<BasketComparison> _comparison = const AsyncLoading();
  var _items = <ItemComparison>[];
  var _leftOut = 0;
  CheckersPlace? _place;
  final _waiting = <ProductRetailer, Queue<int>>{};
  final _asking = <ProductRetailer, int>{};
  var _generation = 0;
  var _isApplying = false;
  var _isDisposed = false;

  AsyncState<BasketComparison> get comparison => _comparison;

  CheckersPlace? get place => _place;

  bool get isApplying => _isApplying;

  /// Unbought items past [itemLimit], not compared.
  int get leftOut => _leftOut;

  void start() {
    if (_generation > 0) return;
    unawaited(_load());
  }

  void retry() {
    if (_comparison is AsyncFailure) {
      unawaited(_load());
      return;
    }
    final again = <ProductRetailer, List<int>>{};
    for (final (index, compared) in _items.indexed) {
      final unreachable = [
        for (final line in compared.lines.values)
          if (line is ShopUnreachable) line.shop,
      ];
      if (unreachable.isEmpty) continue;
      _items[index] = ItemComparison(
        item: compared.item,
        packs: compared.packs,
        lines: Map.unmodifiable({
          for (final MapEntry(key: shop, value: line) in compared.lines.entries)
            if (line is! ShopUnreachable) shop: line,
        }),
      );
      for (final shop in unreachable) {
        (again[shop] ??= []).add(index);
      }
    }
    if (again.isEmpty) return;
    _publish();
    again.forEach((shop, indexes) => _enqueue(shop, indexes, _generation));
  }

  int picksReplacedBy(ProductRetailer shop) =>
      _writesFor(shop).where((write) => write.item.productMatch != null).length;

  int matchesWrittenBy(ProductRetailer shop) => _writesFor(shop).length;

  Future<bool> useShop(ProductRetailer shop) async {
    if (_isApplying) return false;
    final writes = _writesFor(shop);
    if (writes.isEmpty) return true;
    _isApplying = true;
    notifyListeners();
    await runAction(
      () => Future.wait([
        for (final write in writes) _write(write.index, write.product),
      ]),
    );
    _isApplying = false;
    _publish();
    return actionFailure == null;
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _waiting.clear();
    _asking.clear();
    if (_comparison is! AsyncLoading) {
      _comparison = const AsyncLoading();
      notifyListeners();
    }
    final List<GroceryItem> list;
    try {
      list = await _repository.watchItems(householdId).first;
      _place ??= await _places.resolve(householdId);
    } on Object catch (error) {
      if (_isDisposed || generation != _generation) return;
      _comparison = AsyncFailure(
        error is AppFailure ? error : UnknownFailure(error),
      );
      notifyListeners();
      return;
    }
    if (_isDisposed || generation != _generation) return;
    final toBuy = list.where((item) => !item.isBought).toList();
    _leftOut = toBuy.length > itemLimit ? toBuy.length - itemLimit : 0;
    _items = [
      for (final item in toBuy.take(itemLimit))
        ItemComparison(item: item, packs: packsInQuantity(item.quantity)),
    ];
    _publish();
    final indexes = [for (var index = 0; index < _items.length; index++) index];
    for (final shop in shops) {
      _enqueue(shop, indexes, generation);
    }
  }

  void _enqueue(ProductRetailer shop, Iterable<int> indexes, int generation) {
    final queue = (_waiting[shop] ??= Queue())..addAll(indexes);
    while ((_asking[shop] ?? 0) < searchesPerShop && queue.isNotEmpty) {
      _asking[shop] = (_asking[shop] ?? 0) + 1;
      unawaited(_ask(shop, queue, generation));
    }
  }

  Future<void> _ask(
    ProductRetailer shop,
    Queue<int> queue,
    int generation,
  ) async {
    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      final compared = _items[index];
      final line = await _lineAt(shop, compared.item, compared.packs);
      if (_isDisposed || generation != _generation) return;
      _items[index] = _items[index].withLine(line);
      _publish();
    }
    _asking[shop] = (_asking[shop] ?? 1) - 1;
  }

  /// basket-compare ADR-0001 §2: the member's own pick at [shop] wins, live
  /// when the search still returns it and at its picked price when not;
  /// otherwise Jev's best in-stock, by-the-pack product.
  Future<ShopLine> _lineAt(
    ProductRetailer shop,
    GroceryItem item,
    int packs,
  ) async {
    final pick = item.productMatch;
    final ownPick = pick != null && pick.retailer == shop ? pick : null;
    final List<RetailerProduct> found;
    try {
      found = await _catalogues
          .of(shop)
          .search(query: item.name, near: _place!.coordinates);
    } on AppFailure {
      return ownPick == null
          ? ShopUnreachable(shop)
          : _pickedEarlier(ownPick, packs);
    }
    if (ownPick != null) {
      final live = found
          .where((product) => product.id == ownPick.productId)
          .firstOrNull;
      return live == null
          ? _pickedEarlier(ownPick, packs)
          : _offer(live, packs, ShopOfferSource.picked);
    }
    final byThePack = found.where((product) => !product.isSoldByWeight);
    final usable = byThePack.where((product) => product.isInStock).toList();
    if (usable.isEmpty) {
      return ShopMiss(
        shop: shop,
        reason: byThePack.isEmpty
            ? ShopMissReason.notFound
            : ShopMissReason.outOfStock,
      );
    }
    final ranker = _ranker;
    if (ranker == null) {
      return _offer(usable.first, packs, ShopOfferSource.closest);
    }
    final Map<String, double> fits;
    try {
      fits = await ranker.rank(
        householdId: householdId,
        item: item.name,
        products: usable,
      );
    } on AppFailure {
      return _offer(usable.first, packs, ShopOfferSource.closest);
    }
    final best = usable.reduce(
      (best, product) =>
          (fits[product.id] ?? 0) > (fits[best.id] ?? 0) ? product : best,
    );
    return (fits[best.id] ?? 0) >= ProductMatchController.bestMatchFit
        ? _offer(best, packs, ShopOfferSource.matched)
        : ShopMiss(shop: shop, reason: ShopMissReason.notFound);
  }

  ShopOffer _offer(
    RetailerProduct product,
    int packs,
    ShopOfferSource source,
  ) => ShopOffer(
    shop: product.retailer,
    name: product.name,
    brand: product.brand,
    imageId: product.imageId,
    unitPrice: product.price,
    oldPrice: product.oldPrice,
    isOnPromotion: product.isOnPromotion,
    packs: packs,
    source: source,
    product: product,
  );

  ShopOffer _pickedEarlier(ProductMatch pick, int packs) => ShopOffer(
    shop: pick.retailer,
    name: pick.name,
    brand: pick.brand,
    imageId: pick.imageId,
    unitPrice: pick.price,
    packs: packs,
    source: ShopOfferSource.pickedEarlier,
  );

  List<({int index, GroceryItem item, RetailerProduct product})> _writesFor(
    ProductRetailer shop,
  ) => [
    for (final (index, compared) in _items.indexed)
      if (compared.offerAt(shop)?.product case final product?
          when !_isMatchedTo(compared.item, product))
        (index: index, item: compared.item, product: product),
  ];

  static bool _isMatchedTo(GroceryItem item, RetailerProduct product) =>
      item.productMatch?.retailer == product.retailer &&
      item.productMatch?.productId == product.id;

  /// Keeps the item's new match here too, so a second *Use this shop* does
  /// not write it again.
  Future<void> _write(int index, RetailerProduct product) async {
    final match = productMatchFrom(product, pickedBy: _memberId);
    await _repository.setProductMatch(
      householdId: householdId,
      itemId: _items[index].item.id,
      match: match,
    );
    final compared = _items[index];
    _items[index] = ItemComparison(
      item: compared.item.copyWith(productMatch: match),
      packs: compared.packs,
      lines: compared.lines,
    );
  }

  void _publish() {
    _comparison = AsyncData(
      BasketComparison(shops: shops, items: List.unmodifiable(_items)),
    );
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _waiting.clear();
    super.dispose();
  }
}
