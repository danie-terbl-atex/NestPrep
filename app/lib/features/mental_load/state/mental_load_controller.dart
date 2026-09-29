import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../data/card_image_sharer.dart';
import '../model/week_load.dart';
import '../model/week_load_derivation.dart';
import 'load_listeners.dart';

/// The mental-load view's controller (calendar ADR-0006): listens to the
/// reads the calendar, to-dos, groceries and the nanny hub already make,
/// bounded to the week being looked at, and derives who picked up what.
/// It writes nothing — the split exists only on this screen.
final class MentalLoadController extends ChangeNotifier
    with ActionFailureHolder {
  MentalLoadController({
    required LoadListeners loadListeners,
    required CardImageSharer cardImageSharer,
    required HouseholdClock householdClock,
    required List<Member> householdMembers,
    CalendarDate? initialWeekStart,
  }) : _listeners = loadListeners,
       _sharer = cardImageSharer,
       _clock = householdClock,
       _members = householdMembers {
    _weekStart = initialWeekStart ?? _clock.today.weekStart;
    _listeners.open(
      from: _weekStart,
      to: _weekEnd,
      onChange: _publish,
      onError: _fail,
    );
  }

  final LoadListeners _listeners;
  final CardImageSharer _sharer;
  final HouseholdClock _clock;
  List<Member> _members;

  late CalendarDate _weekStart;
  AsyncState<WeekLoad> _week = const AsyncLoading();

  AsyncState<WeekLoad> get week => _week;
  CalendarDate get weekStart => _weekStart;
  CalendarDate get today => _clock.today;
  bool get isThisWeek => _weekStart == today.weekStart;

  CalendarDate get _weekEnd => _weekStart.addDays(6);

  /// The household's people as the shell last saw them — a rename or a new
  /// parent changes the cards with no read of this feature's own.
  void showMembers(List<Member> members) {
    if (listEquals(_members, members)) return;
    _members = members;
    _publish();
  }

  void goToPreviousWeek() => _goTo(_weekStart.addDays(-7));
  void goToNextWeek() => _goTo(_weekStart.addDays(7));
  void goToThisWeek() => _goTo(today.weekStart);

  Future<void> retry() async {
    _week = const AsyncLoading();
    notifyListeners();
    await _listeners.reopen(from: _weekStart, to: _weekEnd);
  }

  /// Shares one adult's card, drawn by the screen as [png] — null when it
  /// could not be drawn — with [text] beside it.
  Future<void> share({required Uint8List? png, required String text}) =>
      runAction(() async {
        if (png == null) {
          throw const MentalLoadFailure(MentalLoadProblem.cardUnreadable);
        }
        await _sharer.share(
          png: png,
          fileName: 'nestprep-week-${_weekStart.iso}.png',
          text: text,
        );
      });

  void _goTo(CalendarDate weekStart) {
    final monday = weekStart.weekStart;
    if (monday == _weekStart) return;
    _weekStart = monday;
    _week = const AsyncLoading();
    notifyListeners();
    unawaited(_listeners.moveWindow(from: _weekStart, to: _weekEnd));
  }

  void _publish() {
    final sources = _listeners.sources;
    if (sources == null) return;
    _week = AsyncData(
      deriveWeekLoad(
        members: _members,
        sources: sources,
        weekStart: _weekStart,
        today: today,
        dayOf: _clock.dateOf,
      ),
    );
    notifyListeners();
  }

  void _fail(AppFailure failure) {
    _week = AsyncFailure(failure);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_listeners.close());
    super.dispose();
  }
}
