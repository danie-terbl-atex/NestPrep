import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../data/calendar_repository.dart';
import '../model/calendar_week.dart';
import '../model/event_exception.dart';
import '../model/event_occurrence.dart';
import '../model/household_event.dart';

/// The calendar's controller. The week being looked at is the one piece of
/// state the screen owns, and the exceptions listener follows it — which is why
/// moving a week reopens that one read and nothing else.
final class CalendarController extends ChangeNotifier with ActionFailureHolder {
  CalendarController({
    required CalendarRepository calendarRepository,
    required HouseholdClock householdClock,
    required this.householdId,
    required this.memberId,
    CalendarDate? initialWeekStart,
  }) : _repository = calendarRepository,
       _clock = householdClock {
    _weekStart = initialWeekStart ?? _clock.today.weekStart;
    _subscribeToEvents();
    _subscribeToExceptions();
  }

  final CalendarRepository _repository;
  final HouseholdClock _clock;
  final String householdId;
  final String memberId;

  StreamSubscription<List<HouseholdEvent>>? _eventSubscription;
  StreamSubscription<List<EventException>>? _exceptionSubscription;

  List<HouseholdEvent>? _events;
  List<EventException>? _exceptions;

  late CalendarDate _weekStart;
  AsyncState<CalendarWeek> _week = const AsyncLoading();
  String? _memberFilter;
  CalendarDate? _selectedDay;

  AsyncState<CalendarWeek> get week => _week;
  CalendarDate get weekStart => _weekStart;
  CalendarDate get today => _clock.today;
  String? get memberFilter => _memberFilter;

  /// The day the agenda is showing: the chosen one, or today when today is in
  /// this week, or the week's Monday.
  CalendarDate get selectedDay =>
      _selectedDay ??
      (today.isInRange(_weekStart, _weekStart.addDays(6)) ? today : _weekStart);

  void selectDay(CalendarDate date) {
    if (_selectedDay == date) return;
    _selectedDay = date;
    notifyListeners();
  }

  void filterBy(String? memberId) {
    if (_memberFilter == memberId) return;
    _memberFilter = memberId;
    _publish();
  }

  void goToWeek(CalendarDate weekStart) {
    final monday = weekStart.weekStart;
    if (monday == _weekStart) return;
    _weekStart = monday;
    _selectedDay = null;
    _exceptions = null;
    _week = const AsyncLoading();
    notifyListeners();
    unawaited(_resubscribeToExceptions());
  }

  void goToPreviousWeek() => goToWeek(_weekStart.addDays(-7));
  void goToNextWeek() => goToWeek(_weekStart.addDays(7));
  void goToThisWeek() => goToWeek(today.weekStart);

  Future<void> retry() async {
    await _cancel();
    _events = null;
    _exceptions = null;
    _week = const AsyncLoading();
    notifyListeners();
    _subscribeToEvents();
    _subscribeToExceptions();
  }

  Future<void> saveEvent({
    String? eventId,
    required String title,
    String? note,
    required CalendarDate date,
    int? startMinute,
    int? endMinute,
    RecurrenceRule? recurrence,
    required List<String> memberIds,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.saveEvent(
        householdId: householdId,
        eventId: eventId,
        title: trimmed,
        note: note?.trim().isEmpty ?? true ? null : note?.trim(),
        date: date,
        startMinute: startMinute,
        endMinute: endMinute,
        recurrence: recurrence,
        memberIds: memberIds,
        createdBy: memberId,
      ),
    );
  }

  Future<void> deleteEvent(String eventId) => runAction(
    () => _repository.deleteEvent(householdId: householdId, eventId: eventId),
  );

  /// Hides one occurrence. Editing a repeating event edits every occurrence;
  /// this is the only per-occurrence change v1 offers (calendar ADR-0001).
  Future<void> skip(EventOccurrence occurrence) => runAction(
    () => _repository.skipOccurrence(
      householdId: householdId,
      eventId: occurrence.event.id,
      occurrenceDate: occurrence.date,
      memberId: memberId,
    ),
  );

  void _subscribeToEvents() {
    _eventSubscription = _repository.watchEvents(householdId).listen((events) {
      _events = events;
      _publish();
    }, onError: _onError);
  }

  void _subscribeToExceptions() {
    _exceptionSubscription = _repository
        .watchExceptions(
          householdId,
          from: _weekStart,
          to: _weekStart.addDays(CalendarWeek.daysInAWeek - 1),
        )
        .listen((exceptions) {
          _exceptions = exceptions;
          _publish();
        }, onError: _onError);
  }

  Future<void> _resubscribeToExceptions() async {
    await _exceptionSubscription?.cancel();
    _exceptionSubscription = null;
    _subscribeToExceptions();
  }

  void _publish() {
    final events = _events;
    final exceptions = _exceptions;
    if (events == null || exceptions == null) return;
    _week = AsyncData(
      CalendarWeek.from(
        occurrences: selectEventOccurrences(
          events: events,
          exceptions: exceptions,
          from: _weekStart,
          to: _weekStart.addDays(CalendarWeek.daysInAWeek - 1),
        ),
        weekStart: _weekStart,
        today: today,
        memberFilter: _memberFilter,
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _week = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _eventSubscription?.cancel();
    await _exceptionSubscription?.cancel();
    _eventSubscription = null;
    _exceptionSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
