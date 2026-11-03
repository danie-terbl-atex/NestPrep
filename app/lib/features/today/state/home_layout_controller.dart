import 'package:flutter/foundation.dart';

import '../data/home_layout_store.dart';
import '../model/home_layout.dart';

final class HomeLayoutController extends ChangeNotifier {
  HomeLayoutController({required this._store, required this.canSwitch}) {
    if (canSwitch) _restore();
  }

  final HomeLayoutStore _store;
  final bool canSwitch;

  var _layout = HomeLayout.tabs;
  var _isDisposed = false;

  // A switch made before the stored layout is read wins over it.
  var _wasChosenHere = false;

  HomeLayout get layout => _layout;

  void switchLayout() {
    if (!canSwitch) return;
    _wasChosenHere = true;
    _layout = _layout.other;
    notifyListeners();
    _store.write(_layout);
  }

  Future<void> _restore() async {
    final saved = await _store.read();
    if (_isDisposed || _wasChosenHere || saved == null || saved == _layout) {
      return;
    }
    _layout = saved;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
