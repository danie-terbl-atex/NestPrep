import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/data/checkers_directory.dart';
import '../../add_to_pnp/data/pnp_directory.dart';
import '../../add_to_woolworths/data/woolworths_directory.dart';
import '../../groceries/model/product_match.dart';
import '../model/shop_link.dart';

/// *Your shops*: whether the member's own account is linked at each shop
/// [shopsOn] names, each read on its own, so one shop that cannot answer
/// never hides the others. A shop switched on while the page is open is read
/// when [switches] says so. A Checkers link that has run out reads as not
/// linked, the way the Checkers link screen treats it.
final class ShopsController extends ChangeNotifier {
  ShopsController({
    required this._checkers,
    required this._pnp,
    required this._woolworths,
    required this._shopsOn,
    this._switches,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _switches?.addListener(_followSwitches);
    _followSwitches();
  }

  final CheckersDirectory _checkers;
  final PnpDirectory _pnp;
  final WoolworthsDirectory _woolworths;
  final List<ProductRetailer> Function() _shopsOn;
  final Listenable? _switches;
  final DateTime Function() _now;

  List<ProductRetailer> get shops => _shopsOn();

  final _links = <ProductRetailer, AsyncState<ShopLink>>{};
  var _isDisposed = false;

  AsyncState<ShopLink> linkAt(ProductRetailer shop) =>
      _links[shop] ?? const AsyncLoading();

  /// Reads [shop]'s link again — after a retry, or coming back from its link
  /// screen. What is known stays on screen until the answer arrives.
  Future<void> refresh(ProductRetailer shop) {
    if (_links[shop] is AsyncFailure) {
      _links[shop] = const AsyncLoading();
      notifyListeners();
    }
    return _load(shop);
  }

  void _followSwitches() {
    for (final shop in shops) {
      if (_links.containsKey(shop)) continue;
      _links[shop] = const AsyncLoading();
      unawaited(_load(shop));
    }
    notifyListeners();
  }

  Future<void> _load(ProductRetailer shop) async {
    AsyncState<ShopLink> loaded;
    try {
      loaded = AsyncData(await _linkStatusAt(shop));
    } on AppFailure catch (failure) {
      loaded = AsyncFailure(failure);
    }
    if (_isDisposed) return;
    _links[shop] = loaded;
    notifyListeners();
  }

  Future<ShopLink> _linkStatusAt(ProductRetailer shop) async {
    switch (shop) {
      case ProductRetailer.checkers:
        final status = await _checkers.linkStatus();
        return status.isLiveAt(_now())
            ? ShopLink(isLinked: true, account: status.mobileMasked)
            : const ShopLink.unlinked();
      case ProductRetailer.pickNPay:
        final status = await _pnp.linkStatus();
        return ShopLink(isLinked: status.isLinked);
      case ProductRetailer.woolworths:
        final status = await _woolworths.linkStatus();
        return status.isLinked
            ? ShopLink(isLinked: true, account: status.emailMasked)
            : const ShopLink.unlinked();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _switches?.removeListener(_followSwitches);
    super.dispose();
  }
}
