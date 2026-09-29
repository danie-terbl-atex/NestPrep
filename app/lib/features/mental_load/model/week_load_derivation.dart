import '../../../shared/time/calendar_date.dart';
import '../../calendar/model/event_occurrence.dart';
import '../../household/model/member.dart';
import '../../todos/model/occurrence_selector.dart';
import 'load_sources.dart';
import 'week_load.dart';

/// Who picked up what in the week starting [weekStart] — derived, never
/// stored (calendar ADR-0006).
///
/// Only the household's adults are counted: its admins and parents. A kid's
/// ticks and a helper's jobs are theirs, and this view is about how the
/// family's own adults share the running of it. Nothing is ranked: the
/// adults keep the household's order, and a quiet week is a quiet week.
///
/// [dayOf] turns an instant into the household's day (`HouseholdClock`),
/// and [today] is when a tick still waiting for the server happened — it
/// was, by definition, just now.
WeekLoad deriveWeekLoad({
  required List<Member> members,
  required LoadSources sources,
  required CalendarDate weekStart,
  required CalendarDate today,
  required CalendarDate Function(DateTime instant) dayOf,
}) {
  final weekEnd = weekStart.addDays(6);
  final tally = _Tally({
    for (final member in members)
      if (member.role.isFamily) member.id: member,
  });
  bool inWeek(CalendarDate day) =>
      !day.isBefore(weekStart) && !day.isAfter(weekEnd);

  final planned = <String>{};
  for (final occurrence in selectEventOccurrences(
    events: sources.events,
    exceptions: sources.exceptions,
    from: weekStart,
    to: weekEnd,
  )) {
    final event = occurrence.event;
    if (planned.add(event.id)) {
      tally.add(event.createdBy, LoadKind.eventsPlanned, event.title);
    }
    for (final memberId in event.memberIds) {
      tally.add(memberId, LoadKind.eventsAttended);
    }
  }

  for (final occurrence in selectOccurrences(
    tasks: sources.tasks,
    routines: sources.routines,
    completions: sources.completions,
    from: weekStart,
    to: weekEnd,
  )) {
    final completion = occurrence.completion;
    if (completion != null) {
      tally.add(
        completion.completedBy,
        LoadKind.todosDone,
        occurrence.task.title,
      );
    } else {
      // "Anyone" is nobody in particular: it is not on one person's plate.
      for (final memberId in occurrence.assigneeIds) {
        tally.add(memberId, LoadKind.todosWaiting);
      }
    }
  }

  for (final item in sources.groceries) {
    final boughtBy = item.boughtBy;
    final boughtAt = item.boughtAt;
    if (boughtBy != null &&
        inWeek(boughtAt == null ? today : dayOf(boughtAt))) {
      tally.add(boughtBy, LoadKind.groceriesBought);
    }
    final addedAt = item.addedAt;
    if (addedAt != null && inWeek(dayOf(addedAt))) {
      tally.add(item.addedBy, LoadKind.groceriesAdded);
    }
  }

  // A shift an adult started or closed for somebody else: the handover,
  // arranged. A carer starting their own shift is the carer's.
  for (final shift in sources.openShifts) {
    final startedAt = shift.startedAt;
    if (startedAt != null &&
        inWeek(dayOf(startedAt)) &&
        shift.startedBy != shift.carerMemberId) {
      tally.add(shift.startedBy, LoadKind.careShifts);
    }
  }
  for (final summary in sources.shiftSummaries) {
    final endedAt = summary.endedAt;
    final endedBy = summary.endedBy;
    if (endedAt != null &&
        endedBy != null &&
        inWeek(dayOf(endedAt)) &&
        endedBy != summary.carerMemberId) {
      tally.add(endedBy, LoadKind.careShifts);
    }
  }

  return WeekLoad(weekStart: weekStart, adults: tally.loads());
}

/// The running counts, one adult at a time; anybody who is not an adult of
/// this household is not counted.
final class _Tally {
  _Tally(this._adults);

  final Map<String, Member> _adults;
  final Map<String, Map<LoadKind, int>> _counts = {};
  final Map<String, List<String>> _highlights = {};

  static const highlightsPerAdult = 3;

  void add(String memberId, LoadKind kind, [String? highlight]) {
    if (!_adults.containsKey(memberId)) return;
    final counts = _counts.putIfAbsent(memberId, () => {});
    counts[kind] = (counts[kind] ?? 0) + 1;
    final title = highlight?.trim();
    if (title == null || title.isEmpty) return;
    final highlights = _highlights.putIfAbsent(memberId, () => []);
    if (highlights.length < highlightsPerAdult && !highlights.contains(title)) {
      highlights.add(title);
    }
  }

  List<AdultLoad> loads() => [
    for (final entry in _adults.entries)
      AdultLoad(
        member: entry.value,
        counts: Map.unmodifiable(_counts[entry.key] ?? const {}),
        highlights: List.unmodifiable(_highlights[entry.key] ?? const []),
      ),
  ];
}
