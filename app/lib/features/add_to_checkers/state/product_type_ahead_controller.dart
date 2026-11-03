import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../groceries/model/product_match.dart';
import '../model/retailer_product.dart';
import 'product_finder.dart';

/// What is being typed, and the shop it is looked up at.
typedef ProductTypeAheadQuery = ({String text, ProductRetailer shop});

/// The chosen shop's products for what somebody is typing into the grocery
/// add field, before anything is on the list (add-to-checkers ADR-0007).
///
/// Nothing here holds the add up: the field adds on its own, and this only
/// offers products to add with. A search waits for [minLength] characters
/// and a [debounce] pause, and an answer for text no longer in the field is
/// dropped. [ProductFinder] keeps each answer, so typing back over a word
/// does not ask again.
final class ProductTypeAheadController extends ChangeNotifier {
  ProductTypeAheadController({
    required this._finder,
    this.debounce = const Duration(milliseconds: 400),
  });

  static const minLength = 3;

  final ProductFinder _finder;
  final Duration debounce;

  ProductTypeAheadQuery? _query;
  AsyncState<List<RetailerProduct>> _products = const AsyncLoading();
  String? _bestMatchId;
  Timer? _timer;
  var _generation = 0;
  var _isDisposed = false;

  /// What the products are for; null when there is nothing to show.
  ProductTypeAheadQuery? get query => _query;

  AsyncState<List<RetailerProduct>> get products => _products;

  String? get bestMatchId => _bestMatchId;

  /// Looks [text] up at [shop] once typing pauses. Shorter than
  /// [minLength] — or blank — clears.
  void lookUp(String text, {required ProductRetailer shop}) {
    final trimmed = text.trim();
    if (trimmed.length < minLength) return clear();
    final next = (text: trimmed, shop: shop);
    if (next == _query) return;
    _timer?.cancel();
    final generation = ++_generation;
    _query = next;
    _products = const AsyncLoading();
    _bestMatchId = null;
    notifyListeners();
    _timer = Timer(debounce, () => unawaited(_search(generation, next)));
  }

  void retry() {
    final query = _query;
    if (query == null) return;
    _query = null;
    lookUp(query.text, shop: query.shop);
  }

  void clear() {
    _timer?.cancel();
    _generation += 1;
    if (_query == null) return;
    _query = null;
    notifyListeners();
  }

  Future<void> _search(int generation, ProductTypeAheadQuery query) async {
    final List<RetailerProduct> found;
    try {
      found = await _finder.search(query.text, at: query.shop);
    } on AppFailure catch (failure) {
      if (_isCurrent(generation)) {
        _products = AsyncFailure(failure);
        notifyListeners();
      }
      return;
    }
    if (!_isCurrent(generation)) return;
    _products = AsyncData(found);
    notifyListeners();
    final ranked = await _finder.rank(query.text, found);
    if (ranked == null || !_isCurrent(generation)) return;
    _products = AsyncData(ranked.products);
    _bestMatchId = ranked.bestMatchId;
    notifyListeners();
  }

  bool _isCurrent(int generation) => !_isDisposed && generation == _generation;

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
