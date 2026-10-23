import 'package:flutter/foundation.dart';

import '../../groceries/model/product_match.dart';
import '../data/retailer_preference.dart';

/// Which shop the grocery screen's *Find at* searches, for one household on
/// this phone (add-to-pnp ADR-0007). It decides nothing else: a match keeps
/// its own shop, and switching never clears one.
///
/// Starts at Checkers and takes the remembered choice once it has been read.
/// [shopsOn] says which connected shops have their switch on now; a choice
/// whose switch is off reads as the first shop that is on, so a lookup never
/// goes to a shop that cannot answer.
final class RetailerChoiceController extends ChangeNotifier {
  RetailerChoiceController({
    required RetailerPreference preference,
    required this.householdId,
    required this._shopsOn,
  }) : _saved = preference {
    _restore();
  }

  final RetailerPreference _saved;
  final List<ProductRetailer> Function() _shopsOn;
  final String householdId;

  var _chosen = ProductRetailer.checkers;
  var _isDisposed = false;

  /// The shop *Find at* searches now.
  ProductRetailer get chosen {
    final on = _shopsOn();
    if (on.contains(_chosen) || on.isEmpty) return _chosen;
    return on.first;
  }

  /// Ignored for a shop that is not connected or switched off; the picker
  /// does not offer one, this is the second lock.
  void choose(ProductRetailer retailer) {
    if (!_shopsOn().contains(retailer) || retailer == _chosen) return;
    _chosen = retailer;
    notifyListeners();
    _saved.write(householdId, retailer);
  }

  Future<void> _restore() async {
    final saved = await _saved.read(householdId);
    if (_isDisposed || saved == null || !saved.isConnected) return;
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
