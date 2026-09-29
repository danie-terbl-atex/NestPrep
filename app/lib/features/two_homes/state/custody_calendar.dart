import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/two_homes_repository.dart';
import '../model/co_parent_link.dart';
import '../model/custody_band.dart';

/// Where each linked child is on each day, for the household's week
/// (household ADR-0004): an all-day band per active link, in the colour of the
/// home the child is with, derived from the schedule every time — like a
/// birthday, never stored as an event.
///
/// Beside the calendar's own controller rather than inside it, so the week
/// stands whether or not this household has any link, and a failure here
/// never takes the week down.
final class CustodyCalendar extends ChangeNotifier {
  CustodyCalendar({
    required TwoHomesRepository twoHomesRepository,
    required this.householdId,
  }) : _repository = twoHomesRepository {
    _subscribe();
  }

  final TwoHomesRepository _repository;
  final String householdId;

  StreamSubscription<List<CoParentLink>>? _subscription;
  List<CoParentLink> _active = const [];
  final _byDay = <CalendarDate, List<CustodyBand>>{};
  AppFailure? _failure;

  /// Why the links could not be read, for the quiet line under the strip.
  AppFailure? get failure => _failure;

  bool get hasLinks => _active.isNotEmpty;

  /// The bands on [date], one per active link, in the order the links were
  /// made. Worked out once per day per emission, not on every build (`FE-12`).
  List<CustodyBand> on(CalendarDate date) => _byDay.putIfAbsent(
    date,
    () => [
      for (final link in _active)
        for (final day in link.daysBetween(date, date))
          CustodyBand(link: link, day: day),
    ],
  );

  /// The home colours on [date], for the week strip's small bar.
  List<MemberColor> coloursOn(CalendarDate date) => [
    for (final band in on(date)) band.home.color,
  ];

  Future<void> retry() async {
    await _subscription?.cancel();
    _failure = null;
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _repository
        .watchLinks(householdId)
        .listen(
          (links) {
            _active = links
                .where((link) => link.isActive)
                .toList()
                .reversed
                .toList();
            _byDay.clear();
            _failure = null;
            notifyListeners();
          },
          onError: (Object error) {
            _failure = error is AppFailure ? error : UnknownFailure(error);
            notifyListeners();
          },
        );
  }

  Future<void> _cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
