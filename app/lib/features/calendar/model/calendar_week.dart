import '../../../shared/time/calendar_date.dart';
import 'birthday_occurrence.dart';
import 'day_entry.dart';
import 'event_occurrence.dart';

/// One week of the household's calendar, already grouped by day — so neither
/// view groups in a build method (`FE-12`).
class CalendarWeek {
  const CalendarWeek({
    required this.weekStart,
    required this.today,
    required this.byDay,
  });

  /// Both lists arrive in the order their own expansion produced, so a day is
  /// merged and never re-sorted: the birthdays lead the day, then the events in
  /// the order the agenda already reads them. One less comparator to drift.
  factory CalendarWeek.from({
    required List<EventOccurrence> occurrences,
    required CalendarDate weekStart,
    required CalendarDate today,
    List<BirthdayOccurrence> birthdays = const [],
    String? memberFilter,
  }) {
    final byDay = <String, List<DayEntry>>{
      for (var day = 0; day < daysInAWeek; day++)
        weekStart.addDays(day).iso: <DayEntry>[],
    };
    for (final birthday in birthdays) {
      if (memberFilter != null && birthday.member.id != memberFilter) continue;
      byDay[birthday.date.iso]?.add(BirthdayEntry(birthday));
    }
    for (final occurrence in occurrences) {
      if (memberFilter != null && !occurrence.event.isFor(memberFilter)) {
        continue;
      }
      byDay[occurrence.date.iso]?.add(EventEntry(occurrence));
    }
    return CalendarWeek(weekStart: weekStart, today: today, byDay: byDay);
  }

  static const daysInAWeek = 7;

  /// The Monday this week starts on (calendar phase 1).
  final CalendarDate weekStart;
  final CalendarDate today;
  final Map<String, List<DayEntry>> byDay;

  List<CalendarDate> get days => [
    for (var day = 0; day < daysInAWeek; day++) weekStart.addDays(day),
  ];

  List<DayEntry> on(CalendarDate date) => byDay[date.iso] ?? const [];

  bool get isEmpty => byDay.values.every((entries) => entries.isEmpty);

  bool get containsToday =>
      !today.isBefore(weekStart) && !today.isAfter(weekStart.addDays(6));
}
