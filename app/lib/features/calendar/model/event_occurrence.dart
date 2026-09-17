import '../../../shared/recurrence/recurrence_expansion.dart';
import '../../../shared/time/calendar_date.dart';
import 'event_exception.dart';
import 'household_event.dart';

/// One event on one day — what a day agenda and a week column are lists of.
class EventOccurrence {
  const EventOccurrence({required this.event, required this.date});

  final HouseholdEvent event;
  final CalendarDate date;

  bool get isAllDay => event.isAllDay;

  String get key => EventException.idFor(event.id, date);
}

/// Expands the household's events into the days a window shows, dropping the
/// occurrences somebody has skipped (calendar ADR-0001, foundation ADR-0005).
///
/// Pure, and the only place a day's agenda is decided, so the day view and the
/// week view can never disagree.
List<EventOccurrence> selectEventOccurrences({
  required List<HouseholdEvent> events,
  required List<EventException> exceptions,
  required CalendarDate from,
  required CalendarDate to,
}) {
  final skipped = {
    for (final exception in exceptions)
      EventException.idFor(exception.eventId, exception.occurrenceDate),
  };

  final occurrences = <EventOccurrence>[];
  for (final event in events) {
    for (final day in expandFor(event, from: from, to: to)) {
      if (skipped.contains(EventException.idFor(event.id, day))) continue;
      occurrences.add(EventOccurrence(event: event, date: day));
    }
  }

  occurrences.sort(_byDayThenTime);
  return occurrences;
}

/// The days one event lands on inside a window.
List<CalendarDate> expandFor(
  HouseholdEvent event, {
  required CalendarDate from,
  required CalendarDate to,
}) => expandOccurrences(
  firstDate: event.date,
  rule: event.recurrence,
  windowStart: from,
  windowEnd: to,
);

/// All-day first, then by the time it starts, then by title so two events at
/// the same time keep their order between rebuilds (`FE-11`).
int _byDayThenTime(EventOccurrence a, EventOccurrence b) {
  final byDay = a.date.compareTo(b.date);
  if (byDay != 0) return byDay;
  final byTime = a.event.sortMinute.compareTo(b.event.sortMinute);
  if (byTime != 0) return byTime;
  final byTitle = a.event.title.toLowerCase().compareTo(
    b.event.title.toLowerCase(),
  );
  return byTitle != 0 ? byTitle : a.event.id.compareTo(b.event.id);
}
