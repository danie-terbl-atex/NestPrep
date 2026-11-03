import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../model/checkers_area.dart';
import '../model/checkers_place.dart';
import '../model/product_match_from.dart';
import '../model/retailer_product.dart';
import 'product_finder.dart';

/// The item whose matches are showing, and the shop they are from.
typedef ProductMatchTarget = ({
  String itemId,
  String name,
  ProductRetailer shop,
});

/// A shop's products under one grocery item at a time — Checkers' or Pick n
/// Pay's, whichever *Shop at* named when the search began (the Checkers
/// build contract, add-to-pnp ADR-0007) — for the grocery screen.
///
/// The search starts only after the item is on the list, and never from a
/// build: the screen calls [lookFor] when an item is added or when somebody
/// taps *Find at*. Quick additions in a row are debounced, so only
/// the last one searches, and an answer for an item no longer showing is
/// dropped. Nothing is copied from the list: a pick is written to the item
/// and arrives back through the list's own listener (`FE-07`).
final class ProductMatchController extends ChangeNotifier
    with ActionFailureHolder {
  ProductMatchController({
    required this._finder,
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
    this.debounce = const Duration(milliseconds: 400),
  }) : _repository = groceryRepository;

  static const bestMatchFit = ProductFinder.bestMatchFit;

  final ProductFinder _finder;
  final GroceryRepository _repository;
  final String householdId;

  /// The profile picking: stored as the match's `pickedBy`.
  final String memberId;
  final Duration debounce;

  ProductMatchTarget? _target;
  AsyncState<List<RetailerProduct>> _matches = const AsyncLoading();
  String? _bestMatchId;
  Timer? _timer;
  var _generation = 0;
  var _isPicking = false;
  var _isDisposed = false;

  /// The item the panel is for; null when no panel is showing.
  ProductMatchTarget? get target => _target;

  AsyncState<List<RetailerProduct>> get matches => _matches;

  /// The product Jev is sure the item means; null until it has answered.
  String? get bestMatchId => _bestMatchId;

  /// Where the last search looked, once it is known.
  CheckersPlace? get place => _finder.place;

  bool get isPicking => _isPicking;

  /// Shows the panel for [item] and searches for its name at [at] after the
  /// debounce. The item's own match is untouched until somebody picks.
  void lookFor(GroceryItem item, {required ProductRetailer at}) {
    _target = (itemId: item.id, name: item.name, shop: at);
    _schedule();
  }

  void retry() {
    if (_target == null) return;
    _schedule();
  }

  /// Closes the panel; an answer still on its way is ignored.
  void dismiss() {
    _timer?.cancel();
    _generation += 1;
    _target = null;
    notifyListeners();
  }

  /// Searches this household's matches near [area] from now on.
  Future<void> chooseArea(CheckersArea area) async {
    await _finder.chooseArea(area);
    if (_target != null) _schedule(immediately: true);
    notifyListeners();
  }

  /// Stores [product] as the target item's match and closes the panel.
  Future<void> pick(RetailerProduct product) async {
    final target = _target;
    if (target == null || _isPicking) return;
    _isPicking = true;
    notifyListeners();
    await runAction(
      () => _repository.setProductMatch(
        householdId: householdId,
        itemId: target.itemId,
        match: productMatchFrom(product, pickedBy: memberId),
      ),
    );
    _isPicking = false;
    if (_isDisposed) return;
    if (actionFailure == null && _target == target) {
      dismiss();
    } else {
      notifyListeners();
    }
  }

  /// Takes the picked product off [item].
  Future<void> clear(GroceryItem item) => runAction(
    () => _repository.clearProductMatch(
      householdId: householdId,
      itemId: item.id,
    ),
  );

  void _schedule({bool immediately = false}) {
    _timer?.cancel();
    final generation = ++_generation;
    _matches = const AsyncLoading();
    _bestMatchId = null;
    notifyListeners();
    _timer = Timer(
      immediately ? Duration.zero : debounce,
      () => unawaited(_search(generation)),
    );
  }

  Future<void> _search(int generation) async {
    final target = _target;
    if (target == null) return;
    AsyncState<List<RetailerProduct>> result;
    try {
      result = AsyncData(await _finder.search(target.name, at: target.shop));
    } on AppFailure catch (failure) {
      result = AsyncFailure(failure);
    }
    if (_isDisposed || generation != _generation) return;
    _matches = result;
    notifyListeners();
    if (result case AsyncData(value: final products)) {
      final ranked = await _finder.rank(target.name, products);
      if (ranked == null || _isDisposed || generation != _generation) return;
      _matches = AsyncData(ranked.products);
      _bestMatchId = ranked.bestMatchId;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
