import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/money/money.dart';
import '../../../shared/state/action_failure.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../model/checkers_area.dart';
import '../model/checkers_place.dart';
import '../model/product_match_from.dart';
import '../model/retailer_product.dart';
import 'product_finder.dart';

enum ListMatchOutcome { waiting, picked, skipped, removed }

/// The grocery list's unmatched items matched at one shop, one item at a
/// time (groceries ADR-0010). A pick is written as its step is left; a
/// removal is only marked, for the list to apply when the page closes.
final class ListMatchController extends ChangeNotifier
    with ActionFailureHolder {
  ListMatchController({
    required this._finder,
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
    required this.shop,
    required List<GroceryItem> items,
  }) : _repository = groceryRepository,
       items = List.unmodifiable(items) {
    unawaited(_load());
  }

  static const productsPerItem = 6;

  final ProductFinder _finder;
  final GroceryRepository _repository;
  final String householdId;
  final String memberId;
  final ProductRetailer shop;
  final List<GroceryItem> items;

  final _outcomes = <String, ListMatchOutcome>{};
  final _picked = <String, RetailerProduct>{};
  var _index = 0;
  RetailerProduct? _selected;
  AsyncState<List<RetailerProduct>> _products = const AsyncLoading();
  String? _bestMatchId;
  var _generation = 0;
  var _isDisposed = false;

  int get index => _index;

  bool get isDone => _index >= items.length;

  bool get canGoBack => _index > 0;

  GroceryItem? get item => isDone ? null : items[_index];

  ListMatchOutcome get outcome =>
      _outcomes[item?.id] ?? ListMatchOutcome.waiting;

  AsyncState<List<RetailerProduct>> get products => _products;

  String? get bestMatchId => _bestMatchId;

  RetailerProduct? get selected => _selected;

  CheckersPlace? get place => _finder.place;

  int get pickedCount => _count(ListMatchOutcome.picked);

  int get skippedCount => _count(ListMatchOutcome.skipped);

  int get removedCount => _count(ListMatchOutcome.removed);

  List<GroceryItem> get removed => [
    for (final item in items)
      if (_outcomes[item.id] == ListMatchOutcome.removed) item,
  ];

  /// A price by the kilogram is not what one pack costs, so it is left out.
  Money? get estimate {
    Money? total;
    for (final item in items) {
      if (_outcomes[item.id] != ListMatchOutcome.picked) continue;
      final product = _picked[item.id];
      if (product == null || product.isSoldByWeight) continue;
      total = total == null ? product.price : total + product.price;
    }
    return total;
  }

  void select(RetailerProduct product) {
    _selected = _selected == product ? null : product;
    notifyListeners();
  }

  /// Moves on at once and writes behind it: Firestore answers a write only
  /// once the server has it, which offline is never.
  void next() {
    final item = this.item;
    final product = _selected;
    if (item == null || product == null) return;
    final before = _picked[item.id];
    if (before != product) {
      _picked[item.id] = product;
      unawaited(_write(item, product, before));
    }
    _outcomes[item.id] = ListMatchOutcome.picked;
    _advance();
  }

  void skip() {
    final item = this.item;
    if (item == null) return;
    _outcomes.putIfAbsent(item.id, () => ListMatchOutcome.skipped);
    _advance();
  }

  void remove() {
    final item = this.item;
    if (item == null) return;
    _outcomes[item.id] = ListMatchOutcome.removed;
    _advance();
  }

  void keep() {
    final item = this.item;
    if (item == null) return;
    if (_picked.containsKey(item.id)) {
      _outcomes[item.id] = ListMatchOutcome.picked;
    } else {
      _outcomes.remove(item.id);
    }
    unawaited(_load());
  }

  void back() {
    if (!canGoBack) return;
    _index -= 1;
    unawaited(_load());
  }

  void retry() => unawaited(_load());

  Future<void> chooseArea(CheckersArea area) async {
    await _finder.chooseArea(area);
    await _load();
  }

  void _advance() {
    _index += 1;
    if (isDone) {
      _generation += 1;
      notifyListeners();
    } else {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final item = this.item;
    if (item == null) return;
    final generation = ++_generation;
    _selected = _picked[item.id];
    _bestMatchId = null;
    _products = const AsyncLoading();
    notifyListeners();
    AsyncState<List<RetailerProduct>> result;
    String? best;
    try {
      final ranked = await _ranked(item.name);
      result = AsyncData(ranked.products);
      best = ranked.bestMatchId;
    } on AppFailure catch (failure) {
      result = AsyncFailure(failure);
    }
    if (_isDisposed || generation != _generation) return;
    _products = result;
    _bestMatchId = best;
    if (result case AsyncData(value: final products)
        when _selected == null && outcome == ListMatchOutcome.waiting) {
      _selected = products
          .where((product) => product.id == best && _isBuyable(product))
          .firstOrNull;
    }
    notifyListeners();
    unawaited(_lookAhead());
  }

  Future<RankedProducts> _ranked(String name) async {
    final found = await _finder.search(name, at: shop, limit: productsPerItem);
    return await _finder.rank(name, found) ??
        (products: found, bestMatchId: null);
  }

  Future<void> _lookAhead() async {
    if (_index + 1 >= items.length) return;
    try {
      await _ranked(items[_index + 1].name);
    } on AppFailure {
      return;
    }
  }

  Future<void> _write(
    GroceryItem item,
    RetailerProduct product,
    RetailerProduct? before,
  ) async {
    try {
      await _repository.setProductMatch(
        householdId: householdId,
        itemId: item.id,
        match: productMatchFrom(product, pickedBy: memberId),
      );
    } on AppFailure catch (failure) {
      if (_isDisposed) return;
      if (_picked[item.id] == product) {
        if (before == null) {
          _picked.remove(item.id);
          if (_outcomes[item.id] == ListMatchOutcome.picked) {
            _outcomes.remove(item.id);
          }
        } else {
          _picked[item.id] = before;
        }
      }
      recordFailure(failure);
    }
  }

  int _count(ListMatchOutcome outcome) =>
      _outcomes.values.where((each) => each == outcome).length;

  static bool _isBuyable(RetailerProduct product) =>
      product.isInStock && !product.isSoldByWeight;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
