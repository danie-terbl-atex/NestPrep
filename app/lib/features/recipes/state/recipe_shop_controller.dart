import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/money/money.dart';
import '../../../shared/state/action_failure.dart';
import '../../add_to_checkers/data/checkers_place_resolver.dart';
import '../../add_to_checkers/data/product_match_ranker.dart';
import '../../add_to_checkers/data/retailer_catalogues.dart';
import '../../add_to_checkers/model/checkers_area.dart';
import '../../add_to_checkers/model/checkers_place.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../add_to_checkers/state/product_match_controller.dart';
import '../../groceries/model/product_match.dart';
import '../../plan_week/model/shop_list_entry.dart';
import '../data/recipe_groceries.dart';
import '../model/recipe_shop_line.dart';

/// *Add to grocer* on a planned recipe (recipes ADR-0005): each ingredient
/// not ticked off, searched at the chosen shop **one at a time** — kind to
/// the shop, whose catalogue client already remembers and backs off, as
/// *Plan my week*'s run is (lunch-box ADR-0012) — Jev's best put first when
/// he can say, then the household's choices onto the grocery list.
///
/// A run that is replaced (another shop, another area, started again) stops
/// reporting: an answer for an old run is dropped.
final class RecipeShopController extends ChangeNotifier
    with ActionFailureHolder {
  RecipeShopController({
    required this._catalogues,
    required CheckersPlaceResolver placeResolver,
    required this._groceries,
    required this.householdId,
    this._ranker,
  }) : _places = placeResolver;

  /// What one search asks the shop for: enough to swap between.
  static const searchLimit = 6;

  final RetailerCatalogues _catalogues;
  final CheckersPlaceResolver _places;
  final RecipeGroceries _groceries;
  final ProductMatchRanker? _ranker;
  final String householdId;

  ProductRetailer? _shop;
  CheckersPlace? _place;
  var _lines = <RecipeShopLine>[];
  var _generation = 0;
  var _isAdding = false;
  var _isDisposed = false;
  List<ShopListEntry>? _listed;
  int _unmatchedAdded = 0;

  /// The shop the run is at; null before the first.
  ProductRetailer? get shop => _shop;

  /// Where the run looks, once known.
  CheckersPlace? get place => _place;

  List<RecipeShopLine> get lines => List.unmodifiable(_lines);

  bool get isSettled => _lines.every((line) => line.isSettled);

  /// The lines that go on the list when it is added.
  int get includedCount => _lines.where((line) => line.isIncluded).length;

  /// What the included products cost together at the shop today — an
  /// estimate, for one pack of each.
  Money? get estimate {
    Money? total;
    for (final line in _lines) {
      if (!line.isIncluded) continue;
      if (line.chosen case final product?) {
        total = total == null ? product.price : total + product.price;
      }
    }
    return total;
  }

  bool get isAdding => _isAdding;

  /// The matched lines as they stand on the grocery list, once added — what
  /// a cart push names. Null until added.
  List<ShopListEntry>? get listed => _listed;

  /// How many lines went on the list in all, once added.
  int? get addedCount => switch (_listed) {
    final listed? =>
      listed.where((entry) => entry.isNew).length + _unmatchedAdded,
    null => null,
  };

  /// Searches each of [lines] at [shop] near the household's place.
  Future<void> start({
    required ProductRetailer shop,
    required List<RecipeShopLine> lines,
  }) async {
    final generation = ++_generation;
    _shop = shop;
    _lines = [...lines];
    _listed = null;
    _unmatchedAdded = 0;
    clearFailureQuietly();
    notifyListeners();
    final place = _place ??= await _resolvedOrFallback();
    if (!_isCurrent(generation)) return;
    notifyListeners();
    for (final line in lines) {
      if (!_isCurrent(generation)) return;
      await _search(line, shop, place, generation);
    }
  }

  /// The same lines, at [shop].
  Future<void> chooseShop(ProductRetailer shop) async {
    if (shop == _shop || _listed != null) return;
    await start(shop: shop, lines: _restarted());
  }

  /// Searches near [area] from now on, for every household match.
  Future<void> chooseArea(CheckersArea area) async {
    await _places.choose(householdId, area);
    _place = CheckersPlace.area(area);
    final shop = _shop;
    if (shop == null || _listed != null) return;
    await start(shop: shop, lines: _restarted());
  }

  void toggle(int index) => _edit(index, (line) => line.toggled());

  void choose(int index, RetailerProduct product) =>
      _edit(index, (line) => line.choosing(product));

  /// Puts the included lines on the grocery list; true when they went on.
  Future<bool> addToList() async {
    if (_isAdding || _listed != null || !isSettled) return _listed != null;
    _isAdding = true;
    notifyListeners();
    try {
      await runAction(() async {
        final added = await _groceries.add(_lines);
        _listed = added.matched;
        _unmatchedAdded = added.unmatched;
      });
    } finally {
      _isAdding = false;
      if (!_isDisposed) notifyListeners();
    }
    return _listed != null;
  }

  Future<void> _search(
    RecipeShopLine line,
    ProductRetailer shop,
    CheckersPlace place,
    int generation,
  ) async {
    _replace(line.searching(), generation);
    RecipeShopLine answered;
    try {
      final products = await _catalogues
          .of(shop)
          .search(
            query: line.name,
            near: place.coordinates,
            limit: searchLimit,
          );
      final best = await _best(line.name, products);
      answered = line.found(_inOrder(products, best), best: best);
    } on AppFailure catch (failure) {
      answered = line.failedWith(failure);
    }
    _replace(answered, generation);
  }

  /// Jev's best for [item], when he is sure enough (foundation ADR-0021).
  /// Ranking is a nicety: when it fails the shop's order stays.
  Future<String?> _best(String item, List<RetailerProduct> products) async {
    final ranker = _ranker;
    if (ranker == null || products.isEmpty) return null;
    try {
      final fits = await ranker.rank(
        householdId: householdId,
        item: item,
        products: products,
      );
      String? best;
      var bestFit = ProductMatchController.bestMatchFit;
      for (final product in products) {
        if (!RecipeShopLine.isBuyable(product)) continue;
        final fit = fits[product.id] ?? 0;
        if (fit >= bestFit) {
          best = product.id;
          bestFit = fit;
        }
      }
      return best;
    } on AppFailure {
      return null;
    }
  }

  static List<RetailerProduct> _inOrder(
    List<RetailerProduct> products,
    String? best,
  ) => best == null
      ? products
      : [
          ...products.where((product) => product.id == best),
          ...products.where((product) => product.id != best),
        ];

  Future<CheckersPlace> _resolvedOrFallback() async {
    try {
      return await _places.resolve(householdId);
    } on AppFailure {
      return const CheckersPlace.area(CheckersArea.fallback);
    }
  }

  List<RecipeShopLine> _restarted() => [
    for (final line in _lines)
      RecipeShopLine(
        index: line.index,
        name: line.name,
        quantity: line.quantity,
        isIncluded: line.isIncluded,
      ),
  ];

  bool _isCurrent(int generation) => !_isDisposed && generation == _generation;

  void _replace(RecipeShopLine line, int generation) {
    if (!_isCurrent(generation)) return;
    _lines = [
      for (final existing in _lines)
        existing.index == line.index ? line : existing,
    ];
    notifyListeners();
  }

  void _edit(int index, RecipeShopLine Function(RecipeShopLine) edit) {
    if (_listed != null) return;
    _lines = [
      for (final line in _lines) line.index == index ? edit(line) : line,
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
