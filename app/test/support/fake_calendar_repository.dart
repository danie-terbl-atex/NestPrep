import 'dart:async';

import 'package:nestprep/features/calendar/data/calendar_repository.dart';
import 'package:nestprep/features/calendar/model/event_exception.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// The calendar's two reads, driven by hand. The exceptions stream is recreated
/// whenever the window moves, which is what lets a test check that moving a
/// week reopens that read and nothing else.
final class FakeCalendarRepository implements CalendarRepository {
  final _events = StreamController<List<HouseholdEvent>>.broadcast();
  StreamController<List<EventException>> _exceptions =
      StreamController<List<EventException>>.broadcast();

  AppFailure? failWritesWith;

  final exceptionWindows = <({CalendarDate from, CalendarDate to})>[];
  final savedEvents = <({String? eventId, String title, int? startMinute})>[];
  final deletedEvents = <String>[];
  final skipped = <({String eventId, CalendarDate date})>[];
  final unskipped = <({String eventId, CalendarDate date})>[];

  void emitEvents(List<HouseholdEvent> events) => _events.add(events);
  void emitExceptions(List<EventException> exceptions) =>
      _exceptions.add(exceptions);
  void failEventsWith(Object error) => _events.addError(error);

  Future<void> close() async {
    await _events.close();
    await _exceptions.close();
  }

  @override
  Stream<List<HouseholdEvent>> watchEvents(String householdId) => _events.stream;

  @override
  Stream<List<EventException>> watchExceptions(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
  }) {
    exceptionWindows.add((from: from, to: to));
    if (_exceptions.hasListener) {
      _exceptions = StreamController<List<EventException>>.broadcast();
    }
    return _exceptions.stream;
  }

  @override
  Future<void> saveEvent({
    required String householdId,
    String? eventId,
    required String title,
    String? note,
    required CalendarDate date,
    int? startMinute,
    int? endMinute,
    RecurrenceRule? recurrence,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    _refuseIfAsked();
    savedEvents.add((eventId: eventId, title: title, startMinute: startMinute));
  }

  @override
  Future<void> deleteEvent({
    required String householdId,
    required String eventId,
  }) async {
    _refuseIfAsked();
    deletedEvents.add(eventId);
  }

  @override
  Future<void> skipOccurrence({
    required String householdId,
    required String eventId,
    required CalendarDate occurrenceDate,
    required String memberId,
  }) async {
    _refuseIfAsked();
    skipped.add((eventId: eventId, date: occurrenceDate));
  }

  @override
  Future<void> unskipOccurrence({
    required String householdId,
    required String eventId,
    required CalendarDate occurrenceDate,
  }) async {
    _refuseIfAsked();
    unskipped.add((eventId: eventId, date: occurrenceDate));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}
