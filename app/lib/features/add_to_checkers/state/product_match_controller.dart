import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../data/checkers_catalogue.dart';
import '../data/checkers_place_resolver.dart';
import '../data/product_match_ranker.dart';
import '../model/checkers_area.dart';
import '../model/checkers_place.dart';
import '../model/checkers_product.dart';

/// The item whose Checkers matches are showing.
typedef ProductMatchTarget = ({String itemId, String name});

/// The Checkers products under one grocery item at a time (the Checkers build
/// contract), for the grocery screen.
///
/// The search starts only after the item is on the list, and never from a
/// build: the screen calls [lookFor] when an item is added or when somebody
/// taps *Find at Checkers*. Quick additions in a row are debounced, so only
/// the last one searches, and an answer for an item no longer showing is
/// dropped. Nothing is copied from the list: a pick is written to the item
/// and arrives back through the list's own listener (`FE-07`).
final class ProductMatchController extends ChangeNotifier
    with ActionFailureHolder {
  ProductMatchController({
    required CheckersCatalogue catalogue,
    required CheckersPlaceResolver placeResolver,
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
    this._ranker,
    this.debounce = const Duration(milliseconds: 400),
  }) : _checkers = catalogue,
       _places = placeResolver,
       _repository = groceryRepository;

  /// Jev's score a match needs before it is called the best (foundation
  /// ADR-0021).
  static const bestMatchFit = 0.6;

  final CheckersCatalogue _checkers;
  final ProductMatchRanker? _ranker;
  final CheckersPlaceResolver _places;
  final GroceryRepository _repository;
  final String householdId;

  /// The profile picking: stored as the match's `pickedBy`.
  final String memberId;
  final Duration debounce;

  ProductMatchTarget? _target;
  AsyncState<List<CheckersProduct>> _matches = const AsyncLoading();
  String? _bestMatchId;
  CheckersPlace? _place;
  Timer? _timer;
  var _generation = 0;
  var _isPicking = false;
  var _isDisposed = false;

  /// The item the panel is for; null when no panel is showing.
  ProductMatchTarget? get target => _target;

  AsyncState<List<CheckersProduct>> get matches => _matches;

  /// The product Jev is sure the item means; null until it has answered.
  String? get bestMatchId => _bestMatchId;

  /// Where the last search looked, once it is known.
  CheckersPlace? get place => _place;

  bool get isPicking => _isPicking;

  /// Shows the panel for [item] and searches for its name after the
  /// debounce.
  void lookFor(GroceryItem item) {
    _target = (itemId: item.id, name: item.name);
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
    await _places.choose(householdId, area);
    _place = CheckersPlace.area(area);
    if (_target != null) _schedule(immediately: true);
    notifyListeners();
  }

  /// Stores [product] as the target item's match and closes the panel.
  Future<void> pick(CheckersProduct product) async {
    final target = _target;
    if (target == null || _isPicking) return;
    _isPicking = true;
    notifyListeners();
    await runAction(
      () => _repository.setProductMatch(
        householdId: householdId,
        itemId: target.itemId,
        match: _matchFrom(product),
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
    AsyncState<List<CheckersProduct>> result;
    try {
      final place = _place ??= await _places.resolve(householdId);
      result = AsyncData(
        await _checkers.search(query: target.name, near: place.coordinates),
      );
    } on AppFailure catch (failure) {
      result = AsyncFailure(failure);
    }
    if (_isDisposed || generation != _generation) return;
    _matches = result;
    notifyListeners();
    if (result case AsyncData(value: final products) when products.isNotEmpty) {
      await _rank(generation, target.name, products);
    }
  }

  /// Puts Jev's best first. Ranking is a nicety: when it fails the shop's
  /// order stays and nothing is said.
  Future<void> _rank(
    int generation,
    String item,
    List<CheckersProduct> products,
  ) async {
    final ranker = _ranker;
    if (ranker == null) return;
    final Map<String, double> fits;
    try {
      fits = await ranker.rank(
        householdId: householdId,
        item: item,
        products: products,
      );
    } on AppFailure {
      return;
    }
    if (_isDisposed || generation != _generation) return;
    final ranked = [...products]
      ..sort((a, b) => (fits[b.id] ?? 0).compareTo(fits[a.id] ?? 0));
    final best = ranked.first;
    _matches = AsyncData(ranked);
    _bestMatchId = (fits[best.id] ?? 0) >= bestMatchFit ? best.id : null;
    notifyListeners();
  }

  ProductMatch _matchFrom(CheckersProduct product) => ProductMatch(
    retailer: ProductRetailer.checkers,
    productId: product.id,
    articleCode: product.articleCode,
    unitOfMeasure: product.unitOfMeasure,
    name: product.name,
    brand: product.brand,
    price: product.price,
    imageId: product.imageId,
    pickedBy: memberId,
  );

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
