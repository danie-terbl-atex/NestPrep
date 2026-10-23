import 'package:flutter/foundation.dart';

import '../../add_to_checkers/data/lunch_shop_preference.dart';
import '../../groceries/model/product_match.dart';

/// Which shop *Plan my week* plans at for one household on this phone
/// (lunch-box ADR-0026) — read by the brief and by the lunch board's row,
/// from one instance at the lunch shell. Starts at Checkers and takes the
/// remembered choice once read; a shop that cannot plan lunches is ignored.
/// Pick n Pay only counts while its switch is on: [shopFor] says which.
final class LunchShopChoice extends ChangeNotifier {
  LunchShopChoice({
    required LunchShopPreference preference,
    required this.householdId,
  }) : _saved = preference {
    _restore();
  }

  final LunchShopPreference _saved;
  final String householdId;

  var _chosen = ProductRetailer.checkers;
  var _isDisposed = false;

  /// Somebody tapped a shop on this phone since it was made — then the
  /// remembered choice, read late, is older news and is dropped.
  var _wasChosenHere = false;

  /// The shop chosen, whether or not it may be used right now.
  ProductRetailer get chosen => _chosen;

  /// The shop to plan at: the chosen one, or Checkers when Pick n Pay is
  /// chosen but switched off ([isPnpOn], the `addToPnp` flag).
  ProductRetailer shopFor({required bool isPnpOn}) =>
      _chosen == ProductRetailer.pickNPay && !isPnpOn
      ? ProductRetailer.checkers
      : _chosen;

  void choose(ProductRetailer shop) {
    if (!shop.isConnected) return;
    final isFirstTap = !_wasChosenHere;
    _wasChosenHere = true;
    if (shop == _chosen && !isFirstTap) return;
    _chosen = shop;
    notifyListeners();
    _saved.write(householdId, shop);
  }

  Future<void> _restore() async {
    final saved = await _saved.read(householdId);
    if (_isDisposed || _wasChosenHere) return;
    if (saved == null || !saved.isConnected) return;
    if (saved == _chosen) return;
    _chosen = saved;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
