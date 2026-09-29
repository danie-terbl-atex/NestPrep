import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';
import '../../calendar_sync/data/calendar_sync_repository.dart';
import '../../calendar_sync/model/synced_event.dart';
import '../../household/model/member.dart';
import '../data/calendar_repository.dart';
import '../model/birthday_occurrence.dart';
import '../model/calendar_week.dart';
import '../model/event_exception.dart';
import '../model/event_occurrence.dart';
import '../model/household_event.dart';

/// The calendar's controller. The week being looked at is the one piece of
/// state the screen owns, and the exceptions listener follows it — which is why
/// moving a week reopens that one read and nothing else.
///
/// The members come from the household shell's listener rather than a read of
/// this feature's own, and the birthdays on the week are derived from them
/// every time the window or the profiles move (birthdays ADR-0001).
///
/// Events imported from connected calendars follow the window like the
/// exceptions do (calendar ADR-0003). They never hold the week back: the
/// household's own events show as soon as they arrive, and imported ones join
/// them when they do.
final class CalendarController extends ChangeNotifier with ActionFailureHolder {
  CalendarController({
    required CalendarRepository calendarRepository,
    required CalendarSyncRepository calendarSyncRepository,
    required HouseholdClock householdClock,
    required this.householdId,
    required this.memberId,
    required List<Member> householdMembers,
    CalendarDate? initialWeekStart,
  }) : _repository = calendarRepository,
       _syncRepository = calendarSyncRepository,
       _clock = householdClock,
       _members = householdMembers {
    _weekStart = initialWeekStart ?? _clock.today.weekStart;
    _subscribeToEvents();
    _subscribeToWindow();
  }

  final CalendarRepository _repository;
  final CalendarSyncRepository _syncRepository;
  final HouseholdClock _clock;
  final String householdId;
  final String memberId;

  StreamSubscription<List<HouseholdEvent>>? _eventSubscription;
  StreamSubscription<List<EventException>>? _exceptionSubscription;
  StreamSubscription<List<SyncedEvent>>? _syncedSubscription;

  List<HouseholdEvent>? _events;
  List<EventException>? _exceptions;
  List<SyncedEvent> _synced = const [];
  List<Member> _members;

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

  /// The household's profiles, as the shell's listener last saw them. Renaming
  /// or recolouring somebody changes their birthday on the week with no write
  /// of any kind, because the entry was never stored.
  void showBirthdaysOf(List<Member> members) {
    if (listEquals(_members, members)) return;
    _members = members;
    _publish();
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
    _synced = const [];
    _week = const AsyncLoading();
    notifyListeners();
    unawaited(_resubscribeToWindow());
  }

  /// Turns to the week [date] is in and opens that day — where something just
  /// added lands, so the member sees it arrive (calendar ADR-0004).
  void showDay(CalendarDate date) {
    goToWeek(date.weekStart);
    selectDay(date);
  }

  void goToPreviousWeek() => goToWeek(_weekStart.addDays(-7));
  void goToNextWeek() => goToWeek(_weekStart.addDays(7));
  void goToThisWeek() => goToWeek(today.weekStart);

  Future<void> retry() async {
    await _cancel();
    _events = null;
    _exceptions = null;
    _synced = const [];
    _week = const AsyncLoading();
    notifyListeners();
    _subscribeToEvents();
    _subscribeToWindow();
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

  /// The two reads that follow the week being looked at.
  void _subscribeToWindow() {
    final weekEnd = _weekStart.addDays(CalendarWeek.daysInAWeek - 1);
    _exceptionSubscription = _repository
        .watchExceptions(householdId, from: _weekStart, to: weekEnd)
        .listen((exceptions) {
          _exceptions = exceptions;
          _publish();
        }, onError: _onError);
    _syncedSubscription = _syncRepository
        .watchSyncedEvents(householdId, from: _weekStart, to: weekEnd)
        .listen(
          (synced) {
            _synced = synced;
            _publish();
          },
          // The household's own week still stands without them; the banner
          // says the imported part could not be read (`ENG-10`).
          onError: (Object error) => recordFailure(
            error is AppFailure ? error : UnknownFailure(error),
          ),
        );
  }

  Future<void> _resubscribeToWindow() async {
    await _exceptionSubscription?.cancel();
    await _syncedSubscription?.cancel();
    _exceptionSubscription = null;
    _syncedSubscription = null;
    _subscribeToWindow();
  }

  void _publish() {
    final events = _events;
    final exceptions = _exceptions;
    if (events == null || exceptions == null) return;
    final weekEnd = _weekStart.addDays(CalendarWeek.daysInAWeek - 1);
    _week = AsyncData(
      CalendarWeek.from(
        occurrences: selectEventOccurrences(
          events: events,
          exceptions: exceptions,
          from: _weekStart,
          to: weekEnd,
        ),
        birthdays: selectBirthdayOccurrences(
          members: _members,
          from: _weekStart,
          to: weekEnd,
        ),
        synced: _synced,
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
    await _syncedSubscription?.cancel();
    _eventSubscription = null;
    _exceptionSubscription = null;
    _syncedSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
