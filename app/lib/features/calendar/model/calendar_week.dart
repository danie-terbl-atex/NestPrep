import '../../../shared/time/calendar_date.dart';
import '../../calendar_sync/model/synced_event.dart';
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
  ///
  /// Imported events (calendar ADR-0003) are merged into that order by the
  /// minute they start, after the household's own at the same minute — so a
  /// member's work meeting sits in the day where it happens, not in a pile at
  /// the end.
  factory CalendarWeek.from({
    required List<EventOccurrence> occurrences,
    required CalendarDate weekStart,
    required CalendarDate today,
    List<BirthdayOccurrence> birthdays = const [],
    List<SyncedEvent> synced = const [],
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
    final weekEnd = weekStart.addDays(daysInAWeek - 1);
    final importedByDay = <String, List<SyncedEntry>>{};
    for (final event in synced) {
      if (memberFilter != null && event.memberId != memberFilter) continue;
      for (final day in event.daysWithin(weekStart, weekEnd)) {
        (importedByDay[day.iso] ??= []).add(SyncedEntry(event, day));
      }
    }
    for (final MapEntry(key: day, value: imported) in importedByDay.entries) {
      final entries = byDay[day];
      if (entries != null) byDay[day] = _mergeByTime(entries, imported);
    }
    return CalendarWeek(weekStart: weekStart, today: today, byDay: byDay);
  }

  /// [entries] in their own order, with [imported] slotted in by start time.
  static List<DayEntry> _mergeByTime(
    List<DayEntry> entries,
    List<SyncedEntry> imported,
  ) {
    final sorted = [...imported]
      ..sort((a, b) {
        final byTime = a.event.sortMinute.compareTo(b.event.sortMinute);
        return byTime != 0 ? byTime : a.event.title.compareTo(b.event.title);
      });
    final merged = <DayEntry>[];
    var next = 0;
    for (final entry in entries) {
      final minute = switch (entry) {
        EventEntry(:final occurrence) => occurrence.event.sortMinute,
        // A birthday leads the day, before anything imported.
        BirthdayEntry() || SyncedEntry() => -2,
      };
      while (next < sorted.length && sorted[next].event.sortMinute < minute) {
        merged.add(sorted[next++]);
      }
      merged.add(entry);
    }
    merged.addAll(sorted.skip(next));
    return merged;
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
