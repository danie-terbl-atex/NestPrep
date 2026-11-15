import 'package:flutter/foundation.dart';

import '../data/appearance_store.dart';
import '../model/appearance.dart';

final class AppearanceController extends ChangeNotifier {
  AppearanceController({required this._store}) {
    _restore();
  }

  final AppearanceStore _store;

  var _appearance = Appearance.auto;
  var _isDisposed = false;

  // A choice made before the stored one is read wins over it.
  var _wasChosenHere = false;

  Appearance get appearance => _appearance;

  void choose(Appearance appearance) {
    _wasChosenHere = true;
    if (appearance == _appearance) return;
    _appearance = appearance;
    notifyListeners();
    _store.write(appearance);
  }

  Future<void> _restore() async {
    final saved = await _store.read();
    if (_isDisposed ||
        _wasChosenHere ||
        saved == null ||
        saved == _appearance) {
      return;
    }
    _appearance = saved;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
