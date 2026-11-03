import 'package:flutter/foundation.dart';

import '../data/lunch_variety_store.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_variety.dart';

/// Which compartments keep the same all week for one household on this
/// phone (lunch-box ADR-0028) — read by *Plan my week*, *Fill the week* and
/// the board's auto-fill, from one instance at the lunch shell. Starts at
/// [LunchVariety.standard] and takes the remembered choice once read.
final class LunchVarietyChoice extends ChangeNotifier {
  LunchVarietyChoice({required this._store, required this.householdId}) {
    _restore();
  }

  final LunchVarietyStore _store;
  final String householdId;

  var _variety = LunchVariety.standard;
  var _isDisposed = false;

  /// Somebody tapped a chip on this phone since it was made — then the
  /// remembered choice, read late, is older news and is dropped.
  var _wasChosenHere = false;

  LunchVariety get variety => _variety;

  void toggle(LunchSlot slot) {
    _wasChosenHere = true;
    _variety = _variety.toggled(slot);
    notifyListeners();
    _store.write(householdId, _variety);
  }

  Future<void> _restore() async {
    final saved = await _store.read(householdId);
    if (_isDisposed || _wasChosenHere || saved == null || saved == _variety) {
      return;
    }
    _variety = saved;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
