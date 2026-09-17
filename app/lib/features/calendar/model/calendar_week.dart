import '../../../shared/time/calendar_date.dart';
import 'event_occurrence.dart';

/// One week of the household's calendar, already grouped by day — so neither
/// view groups in a build method (`FE-12`).
class CalendarWeek {
  const CalendarWeek({
    required this.weekStart,
    required this.today,
    required this.byDay,
  });

  factory CalendarWeek.from({
    required List<EventOccurrence> occurrences,
    required CalendarDate weekStart,
    required CalendarDate today,
    String? memberFilter,
  }) {
    final byDay = <String, List<EventOccurrence>>{
      for (var day = 0; day < daysInAWeek; day++)
        weekStart.addDays(day).iso: <EventOccurrence>[],
    };
    for (final occurrence in occurrences) {
      if (memberFilter != null && !occurrence.event.isFor(memberFilter)) {
        continue;
      }
      byDay[occurrence.date.iso]?.add(occurrence);
    }
    return CalendarWeek(weekStart: weekStart, today: today, byDay: byDay);
  }

  static const daysInAWeek = 7;

  /// The Monday this week starts on (calendar phase 1).
  final CalendarDate weekStart;
  final CalendarDate today;
  final Map<String, List<EventOccurrence>> byDay;

  List<CalendarDate> get days => [
    for (var day = 0; day < daysInAWeek; day++) weekStart.addDays(day),
  ];

  List<EventOccurrence> on(CalendarDate date) => byDay[date.iso] ?? const [];

  bool get isEmpty => byDay.values.every((events) => events.isEmpty);

  bool get containsToday =>
      !today.isBefore(weekStart) && !today.isAfter(weekStart.addDays(6));
}
