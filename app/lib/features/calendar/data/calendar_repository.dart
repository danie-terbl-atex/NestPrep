import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/event_exception.dart';
import '../model/household_event.dart';

/// What the calendar needs from Firestore.
///
/// Events are read whole: a recurring event has to be read whatever window is
/// showing, and one household has tens of them (foundation ADR-0005).
/// Exceptions are windowed, because those grow with use (`BE-08`).
abstract interface class CalendarRepository {
  Stream<List<HouseholdEvent>> watchEvents(String householdId);

  Stream<List<EventException>> watchExceptions(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
  });

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
  });

  Future<void> deleteEvent({
    required String householdId,
    required String eventId,
  });

  /// Hides one occurrence of a repeating event. Skipping the same one twice is
  /// the same write (`BE-06`).
  Future<void> skipOccurrence({
    required String householdId,
    required String eventId,
    required CalendarDate occurrenceDate,
    required String memberId,
  });

  Future<void> unskipOccurrence({
    required String householdId,
    required String eventId,
    required CalendarDate occurrenceDate,
  });

  static const eventLimit = 500;
}
