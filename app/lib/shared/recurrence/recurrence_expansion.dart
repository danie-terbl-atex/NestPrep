import '../time/calendar_date.dart';
import 'recurrence_rule.dart';

/// Expands a stored recurrence rule into the days it lands on inside a window
/// (foundation ADR-0005). Calendar and todos both read this one function, so a
/// change here changes both features.
///
/// Everything is calendar-date arithmetic: the household's timezone was already
/// applied by `HouseholdClock` when the window was chosen, and a rule that
/// repeats "every Tuesday" means the household's Tuesday whatever the instants
/// underneath it are.
///
/// Returns the occurrences in ascending order, each one inside
/// `[windowStart, windowEnd]` inclusive and never before [firstDate].
List<CalendarDate> expandOccurrences({
  required CalendarDate firstDate,
  required RecurrenceRule? rule,
  required CalendarDate windowStart,
  required CalendarDate windowEnd,
}) {
  if (windowEnd.isBefore(windowStart)) return const [];

  // A thing with no rule, or with a rule this build cannot read, happens once
  // on its own day (`BE-10`).
  if (rule == null || !rule.isExpandable) {
    return firstDate.isInRange(windowStart, windowEnd) ? [firstDate] : const [];
  }

  final lastDay = _lastDay(rule, windowEnd);
  if (lastDay == null || lastDay.isBefore(firstDate)) return const [];

  final from = windowStart.isAfter(firstDate) ? windowStart : firstDate;

  return switch (rule.frequency) {
    RecurrenceFrequency.daily => _expandDaily(firstDate, rule, from, lastDay),
    RecurrenceFrequency.weekly => _expandWeekly(firstDate, rule, from, lastDay),
    RecurrenceFrequency.monthly => _expandMonthly(
      firstDate,
      rule,
      from,
      lastDay,
    ),
  };
}

/// The last day an occurrence may fall on: the window's end, pulled back to the
/// rule's own end date when it has one. Null when the rule ended before the
/// window opened.
CalendarDate? _lastDay(RecurrenceRule rule, CalendarDate windowEnd) {
  final until = rule.until;
  if (until == null) return windowEnd;
  return until.isBefore(windowEnd) ? until : windowEnd;
}

List<CalendarDate> _expandDaily(
  CalendarDate firstDate,
  RecurrenceRule rule,
  CalendarDate from,
  CalendarDate lastDay,
) {
  // Step straight to the first occurrence at or after the window rather than
  // walking every skipped day, so a daily rule from years ago costs the same as
  // one from yesterday (`FE-12`).
  final elapsed = firstDate.daysUntil(from);
  final skipped = (elapsed + rule.interval - 1) ~/ rule.interval;
  var day = firstDate.addDays(skipped * rule.interval);

  final occurrences = <CalendarDate>[];
  while (!day.isAfter(lastDay)) {
    occurrences.add(day);
    day = day.addDays(rule.interval);
  }
  return occurrences;
}

List<CalendarDate> _expandWeekly(
  CalendarDate firstDate,
  RecurrenceRule rule,
  CalendarDate from,
  CalendarDate lastDay,
) {
  final weekdays = rule.weekdays.isEmpty
      ? [firstDate.weekday]
      : (rule.weekdays.toSet().toList()..sort());

  // Weeks are counted from the week the first occurrence falls in, so "every
  // second week" means every second week of the household's calendar and not
  // every fourteenth day from an arbitrary Sunday.
  final firstWeekStart = firstDate.weekStart;
  final elapsedWeeks = firstWeekStart.daysUntil(from.weekStart) ~/ 7;
  final skippedWeeks = (elapsedWeeks + rule.interval - 1) ~/ rule.interval;
  var weekStart = firstWeekStart.addDays(skippedWeeks * rule.interval * 7);

  final occurrences = <CalendarDate>[];
  while (!weekStart.isAfter(lastDay)) {
    for (final weekday in weekdays) {
      final day = weekStart.addDays(weekday - 1);
      if (day.isBefore(firstDate) || day.isAfter(lastDay)) continue;
      occurrences.add(day);
    }
    weekStart = weekStart.addDays(rule.interval * 7);
  }
  return occurrences;
}

List<CalendarDate> _expandMonthly(
  CalendarDate firstDate,
  RecurrenceRule rule,
  CalendarDate from,
  CalendarDate lastDay,
) {
  final elapsedMonths =
      ((from.year - firstDate.year) * 12) + (from.month - firstDate.month);
  final skipped = elapsedMonths <= 0
      ? 0
      : (elapsedMonths + rule.interval - 1) ~/ rule.interval;

  final occurrences = <CalendarDate>[];
  for (var step = skipped; ; step++) {
    final day = firstDate.addMonthsKeepingDay(step * rule.interval);
    // A month too short for this day-of-month has no occurrence: the 31st does
    // not become the 28th (foundation ADR-0005). Keep stepping — the month
    // after it may well have a 31st.
    if (day == null) {
      if (_monthAfter(firstDate, step * rule.interval).isAfter(lastDay)) break;
      continue;
    }
    if (day.isAfter(lastDay)) break;
    if (day.isBefore(firstDate)) continue;
    occurrences.add(day);
  }
  return occurrences;
}

/// The first day of the month `months` after [from]'s — the cheap way to ask
/// "have we stepped past the window yet" when the day-of-month does not exist.
CalendarDate _monthAfter(CalendarDate from, int months) {
  final total = (from.year * 12) + (from.month - 1) + months;
  return CalendarDate(total ~/ 12, (total % 12) + 1, 1);
}
