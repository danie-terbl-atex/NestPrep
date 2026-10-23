import 'package:flutter/foundation.dart';

import '../model/tour_place.dart';
import '../model/tour_stop.dart';

/// How a tour ended.
enum TourEnd { finished, skipped }

/// Where the welcome tour is (welcome-tour ADR-0002): which stops, which one
/// is showing, and how it ended. Pure state — moving the router, finding the
/// component and drawing the spotlight are the tour layer's.
///
/// It lives as long as the household shell, so a shell that opened the tour
/// by itself once does not open it again ([hasAutoStarted]).
final class TourController extends ChangeNotifier {
  List<TourStop> _stops = const [];
  int _index = 0;
  bool _isActive = false;
  bool _isMovingBack = false;
  bool _hasAutoStarted = false;
  TourPlace _finishOn = TourPlace.today;
  TourEnd? _lastEnd;

  bool get isActive => _isActive;
  List<TourStop> get stops => _stops;
  int get index => _index;
  int get count => _stops.length;
  bool get isFirst => _index == 0;
  bool get isLast => _index == _stops.length - 1;
  TourStop? get current => _isActive ? _stops[_index] : null;

  /// Where the last step's way on goes — the lunch board for somebody who
  /// plans lunches, otherwise Today.
  TourPlace get finishOn => _finishOn;

  /// How the tour last ended; null while it runs or before it ever has.
  TourEnd? get lastEnd => _lastEnd;

  /// Whether the shell has opened the tour by itself already.
  bool get hasAutoStarted => _hasAutoStarted;

  /// Remembered before the start is scheduled, so a rebuild in between does
  /// not schedule a second one.
  void markAutoStarted() => _hasAutoStarted = true;

  void start(List<TourStop> stops, {TourPlace finishOn = TourPlace.today}) {
    if (stops.isEmpty) return;
    _stops = List.unmodifiable(stops);
    _index = 0;
    _isMovingBack = false;
    _finishOn = finishOn;
    _lastEnd = null;
    _isActive = true;
    notifyListeners();
  }

  void next() {
    if (!_isActive) return;
    if (isLast) return finish();
    _index += 1;
    _isMovingBack = false;
    notifyListeners();
  }

  void back() {
    if (!_isActive || isFirst) return;
    _index -= 1;
    _isMovingBack = true;
    notifyListeners();
  }

  /// Android back: a step back, or out of the tour from its first step.
  void backOrSkip() => isFirst ? skip() : back();

  void skip() => _end(TourEnd.skipped);

  void finish() => _end(TourEnd.finished);

  /// The current stop's component is not on the screen: it is dropped, and
  /// the tour goes on the way it was going — back past it if it was going
  /// back and there is anything before it. A tour with nothing left ends.
  void dropCurrent() {
    if (!_isActive) return;
    final remaining = [..._stops]..removeAt(_index);
    if (remaining.isEmpty) {
      _stops = const [];
      return _end(TourEnd.finished);
    }
    _stops = List.unmodifiable(remaining);
    if (_isMovingBack && _index > 0) _index -= 1;
    if (_index >= _stops.length) _index = _stops.length - 1;
    notifyListeners();
  }

  void _end(TourEnd end) {
    if (!_isActive) return;
    _isActive = false;
    _lastEnd = end;
    notifyListeners();
  }
}
