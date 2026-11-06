import 'package:flutter/foundation.dart';

import '../../add_to_checkers/data/lunch_shop_preference.dart';
import '../../add_to_checkers/data/retailer_preference.dart';
import '../../groceries/model/product_match.dart';

/// Which shop *Plan my week* plans at for one household on this phone
/// (lunch-box ADR-0026) — read by the brief and by the lunch board's row,
/// from one instance at the lunch shell. A shop chosen in the lunch builder
/// is remembered there; until one is, the family's own shop (*Your shops*,
/// the [RetailerPreference] the grocery list reads) leads. Only a shop
/// switched on counts: [shopFor] says which.
final class LunchShopChoice extends ChangeNotifier {
  LunchShopChoice({
    required LunchShopPreference preference,
    required RetailerPreference familyPreference,
    required this.householdId,
  }) : _saved = preference,
       _family = familyPreference {
    _restore();
  }

  final LunchShopPreference _saved;
  final RetailerPreference _family;
  final String householdId;

  ProductRetailer? _chosen;
  ProductRetailer? _familyShop;
  var _isDisposed = false;

  /// Somebody tapped a shop on this phone since it was made — then the
  /// remembered choice, read late, is older news and is dropped.
  var _wasChosenHere = false;

  /// The shop chosen in the lunch builder, whether or not it may be used
  /// right now.
  ProductRetailer? get chosen => _chosen;

  /// The shop to plan at among [available], the shops switched on in their
  /// order: the one chosen here, else the family's, else the first — null
  /// when none is on.
  ProductRetailer? shopFor(List<ProductRetailer> available) => [
    ?_chosen,
    ?_familyShop,
    ...available,
  ].where(available.contains).firstOrNull;

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
    final (saved, family) = await (
      _saved.read(householdId),
      _family.read(householdId),
    ).wait;
    if (_isDisposed) return;
    final chosen = _wasChosenHere || saved == null || !saved.isConnected
        ? _chosen
        : saved;
    if (chosen == _chosen && family == _familyShop) return;
    _chosen = chosen;
    _familyShop = family;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
