import 'package:flutter/foundation.dart';

import '../../../shared/recurrence/recurrence_expansion.dart';
import '../../../shared/time/calendar_date.dart';
import 'custody_schedule.dart';
import 'custody_side.dart';

/// One day of a linked child's life between two homes: which home, and
/// whether it is the day they change (household ADR-0004).
@immutable
class CustodyDay {
  const CustodyDay({
    required this.date,
    required this.side,
    required this.isHandover,
  });

  final CalendarDate date;
  final CustodySide side;

  /// The child goes from the other home to [side] on this day.
  final bool isHandover;

  @override
  bool operator ==(Object other) =>
      other is CustodyDay &&
      other.date == date &&
      other.side == side &&
      other.isHandover == isHandover;

  @override
  int get hashCode => Object.hash(date, side, isHandover);
}

/// The home on every day from [from] to [to] that the schedule reaches.
///
/// The schedule's blocks are expanded by the recurrence model — the one
/// expansion todos and the calendar read (foundation ADR-0005) — and then an
/// accepted swap's days win over them. An override this build cannot read is
/// ignored rather than guessed at (`BE-10`).
Map<CalendarDate, CustodySide> custodySidesBetween({
  required CustodySchedule schedule,
  required Map<String, String> overrides,
  required CalendarDate from,
  required CalendarDate to,
}) {
  final sides = <CalendarDate, CustodySide>{};
  if (to.isBefore(from)) return sides;
  for (final block in schedule.rules) {
    for (final day in expandOccurrences(
      firstDate: block.firstDate,
      rule: block.rule,
      windowStart: from,
      windowEnd: to,
    )) {
      sides[day] = block.side;
    }
  }
  for (final MapEntry(key: iso, value: name) in overrides.entries) {
    final side = CustodySide.fromName(name);
    final date = _parseOrNull(iso);
    if (side == null || date == null || !date.isInRange(from, to)) continue;
    sides[date] = side;
  }
  return sides;
}

/// Every day from [from] to [to] the child has a home, in order, each
/// knowing whether it is a handover. The day before [from] is read too, so
/// the first day of a window is a handover when it should be.
List<CustodyDay> custodyDaysBetween({
  required CustodySchedule schedule,
  required Map<String, String> overrides,
  required CalendarDate from,
  required CalendarDate to,
}) {
  final sides = custodySidesBetween(
    schedule: schedule,
    overrides: overrides,
    from: from.addDays(-1),
    to: to,
  );
  final days = <CustodyDay>[];
  for (var date = from; !date.isAfter(to); date = date.addDays(1)) {
    final side = sides[date];
    if (side == null) continue;
    final before = sides[date.addDays(-1)];
    days.add(
      CustodyDay(
        date: date,
        side: side,
        isHandover: before != null && before != side,
      ),
    );
  }
  return days;
}

/// The next [count] handovers on or after [from], looking no further than
/// [horizonDays] — a schedule with no change in twelve weeks has nothing
/// coming (`FE-12`: bounded, however odd the schedule).
List<CustodyDay> upcomingHandovers({
  required CustodySchedule schedule,
  required Map<String, String> overrides,
  required CalendarDate from,
  int count = 4,
  int horizonDays = 84,
}) => custodyDaysBetween(
  schedule: schedule,
  overrides: overrides,
  from: from,
  to: from.addDays(horizonDays),
).where((day) => day.isHandover).take(count).toList();

CalendarDate? _parseOrNull(String iso) {
  try {
    return CalendarDate.parse(iso);
  } on FormatException {
    return null;
  }
}
