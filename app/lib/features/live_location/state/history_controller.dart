import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../data/places_repository.dart';
import '../data/trail_repository.dart';
import '../model/family_place.dart';
import '../model/timeline.dart';
import '../model/trail.dart';

class MemberDay {
  const MemberDay({
    required this.day,
    required this.trail,
    required this.timeline,
    required this.places,
  });

  final CalendarDate day;
  final TrailDay trail;
  final List<TimelineEntry> timeline;
  final List<FamilyPlace> places;

  bool get isEmpty => trail.isEmpty;
}

/// One member's day, read from one document (live-location ADR-0004).
final class HistoryController extends ChangeNotifier {
  HistoryController({
    required TrailRepository trailRepository,
    required PlacesRepository placesRepository,
    required this.householdId,
    required this.memberId,
    required HouseholdClock clock,
  }) : _trails = trailRepository,
       _clock = clock,
       _day = clock.today {
    _placeSubscription = placesRepository
        .watchPlaces(householdId)
        .listen(
          _onPlaces,
          onError: (Object error) => AppLog.failure(
            'history places',
            code: 'history-places-failed',
            error: error,
          ),
        );
    unawaited(_load());
  }

  final TrailRepository _trails;
  final HouseholdClock _clock;
  final String householdId;
  final String memberId;
  StreamSubscription<List<FamilyPlace>>? _placeSubscription;
  List<FamilyPlace> _places = const [];
  TrailDay? _trail;
  CalendarDate _day;
  AsyncState<MemberDay> _view = const AsyncLoading();

  AsyncState<MemberDay> get view => _view;
  CalendarDate get day => _day;

  CalendarDate get earliest =>
      _clock.today.addDays(-(TrailRepository.retention.inDays - 1));

  bool get canGoBack => _day.isAfter(earliest);
  bool get canGoForward => _day.isBefore(_clock.today);

  Future<void> showDay(CalendarDate day) async {
    if (day.isAfter(_clock.today) || day.isBefore(earliest)) return;
    _day = day;
    await _load();
  }

  /// A member's own history only; the rules refuse anybody else's.
  Future<void> clearHistory() async {
    try {
      await _trails.clearHistory(householdId: householdId, memberId: memberId);
      await _load();
    } on AppFailure catch (failure) {
      _view = AsyncFailure(failure);
      notifyListeners();
    }
  }

  Future<void> previousDay() => showDay(_day.addDays(-1));
  Future<void> nextDay() => showDay(_day.addDays(1));
  Future<void> retry() => _load();

  Future<void> _load() async {
    final day = _day;
    _view = const AsyncLoading();
    notifyListeners();
    try {
      final trail = await _trails.loadDay(
        householdId: householdId,
        memberId: memberId,
        day: day,
        from: _clock.startOfDay(day),
        to: _clock.endOfDay(day),
      );
      if (day != _day) return;
      _trail = trail;
      _publish();
    } on AppFailure catch (failure) {
      if (day != _day) return;
      _view = AsyncFailure(failure);
      notifyListeners();
    }
  }

  void _onPlaces(List<FamilyPlace> places) {
    _places = places;
    if (_trail != null) _publish();
  }

  void _publish() {
    final trail = _trail ?? TrailDay.empty;
    _view = AsyncData(
      MemberDay(
        day: _day,
        trail: trail,
        timeline: Timeline.of(trail, _places),
        places: _places,
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_placeSubscription?.cancel());
    super.dispose();
  }
}
