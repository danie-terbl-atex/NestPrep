import 'package:flutter/foundation.dart';

import '../../groceries/model/product_match.dart';
import '../data/retailer_preference.dart';

/// Which shop the grocery screen looks things up at, for one household on
/// this phone. Starts at Checkers — the one shop connected today — and takes
/// the remembered choice once it has been read. A remembered shop that is not
/// connected (any more) is ignored, so a lookup never goes nowhere.
final class RetailerChoiceController extends ChangeNotifier {
  RetailerChoiceController({
    required RetailerPreference preference,
    required this.householdId,
  }) : _saved = preference {
    _restore();
  }

  final RetailerPreference _saved;
  final String householdId;

  var _chosen = ProductRetailer.checkers;
  var _isDisposed = false;

  ProductRetailer get chosen => _chosen;

  /// Ignored for a shop that is not connected yet; the picker does not offer
  /// one, this is the second lock.
  void choose(ProductRetailer retailer) {
    if (!retailer.isConnected || retailer == _chosen) return;
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
