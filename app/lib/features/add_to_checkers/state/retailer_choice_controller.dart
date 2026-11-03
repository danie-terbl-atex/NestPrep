import 'package:flutter/foundation.dart';

import '../../groceries/model/product_match.dart';
import '../data/match_as_you_type_preference.dart';
import '../data/retailer_preference.dart';

/// Which shop the grocery screen's *Find at* searches, for one household on
/// this phone (add-to-pnp ADR-0007), and whether the add field shows that
/// shop's products while somebody types (add-to-checkers ADR-0007). It
/// decides nothing else: a match keeps its own shop, and switching never
/// clears one.
///
/// Starts at Checkers and takes the remembered choice once it has been read.
/// [shopsOn] says which connected shops have their switch on now; a choice
/// whose switch is off reads as the first shop that is on, so a lookup never
/// goes to a shop that cannot answer.
final class RetailerChoiceController extends ChangeNotifier {
  RetailerChoiceController({
    required RetailerPreference preference,
    required MatchAsYouTypePreference matchAsYouType,
    required this.householdId,
    required this._shopsOn,
  }) : _saved = preference,
       _savedMatching = matchAsYouType {
    _restore();
  }

  final RetailerPreference _saved;
  final MatchAsYouTypePreference _savedMatching;
  final List<ProductRetailer> Function() _shopsOn;
  final String householdId;

  var _chosen = ProductRetailer.checkers;
  var _matchesAsYouType = true;
  var _isDisposed = false;

  /// On until somebody on this phone turns it off.
  bool get matchesAsYouType => _matchesAsYouType;

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

  /// Choosing a shop to match at turns matching as you type on with it.
  void matchAsYouTypeAt(ProductRetailer retailer) {
    choose(retailer);
    setMatchesAsYouType(isOn: true);
  }

  void setMatchesAsYouType({required bool isOn}) {
    if (_matchesAsYouType == isOn) return;
    _matchesAsYouType = isOn;
    notifyListeners();
    _savedMatching.writeMatchAsYouType(householdId, isOn: isOn);
  }

  Future<void> _restore() async {
    final (saved, matching) = await (
      _saved.read(householdId),
      _savedMatching.readMatchAsYouType(householdId),
    ).wait;
    if (_isDisposed) return;
    var changed = false;
    if (saved != null && saved.isConnected && saved != _chosen) {
      _chosen = saved;
      changed = true;
    }
    if (matching != null && matching != _matchesAsYouType) {
      _matchesAsYouType = matching;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
