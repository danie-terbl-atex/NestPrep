import '../../../shared/time/calendar_date.dart';
import 'custody_schedule.dart';
import 'custody_side.dart';

/// The schedules a family picks from, built as blocks (household ADR-0004).
///
/// Every preset is a fortnight from a Monday, written out day by day and
/// grouped into one block per home per week — so a preset and a custom
/// fortnight tapped day by day are the same shape, and the server checks both
/// the same way.
abstract final class CustodyPresets {
  static const fortnight = 2;
  static const daysInAWeek = 7;

  /// A week in one home, a week in the other. [first] has the child from
  /// [switchWeekday] of the first week; the child changes homes on that
  /// weekday every week after.
  static CustodySchedule alternatingWeeks({
    required CalendarDate startsOn,
    required CustodySide first,
    int switchWeekday = DateTime.monday,
    int? handoverMinute,
  }) => fromCycle(
    pattern: CustodyPattern.alternatingWeeks,
    startsOn: startsOn,
    handoverMinute: handoverMinute,
    days: [
      for (var weekday = 1; weekday <= daysInAWeek; weekday++)
        weekday < switchWeekday ? first.other : first,
      for (var weekday = 1; weekday <= daysInAWeek; weekday++)
        weekday < switchWeekday ? first : first.other,
    ],
  );

  /// Two days, two days, three days, then the other way round the next week:
  /// neither home goes more than three days without the child.
  static CustodySchedule twoTwoThree({
    required CalendarDate startsOn,
    required CustodySide first,
    int? handoverMinute,
  }) {
    List<CustodySide> week(CustodySide home) => [
      home,
      home,
      home.other,
      home.other,
      home,
      home,
      home,
    ];
    return fromCycle(
      pattern: CustodyPattern.twoTwoThree,
      startsOn: startsOn,
      handoverMinute: handoverMinute,
      days: [...week(first), ...week(first.other)],
    );
  }

  /// The child lives with [primary] and spends every other weekend, Friday to
  /// Sunday, with the other home — starting this first week's.
  static CustodySchedule everyOtherWeekend({
    required CalendarDate startsOn,
    required CustodySide primary,
    int? handoverMinute,
  }) => fromCycle(
    pattern: CustodyPattern.everyOtherWeekend,
    startsOn: startsOn,
    handoverMinute: handoverMinute,
    days: [
      for (var weekday = 1; weekday <= daysInAWeek; weekday++)
        weekday >= DateTime.friday ? primary.other : primary,
      for (var weekday = 1; weekday <= daysInAWeek; weekday++) primary,
    ],
  );

  /// Any cycle of whole weeks, one home per day from its first Monday.
  static CustodySchedule fromCycle({
    required CustodyPattern pattern,
    required CalendarDate startsOn,
    required List<CustodySide> days,
    int? handoverMinute,
  }) {
    final weeks = days.length ~/ daysInAWeek;
    final blocks = <CustodyBlock>[];
    for (var week = 0; week < weeks; week++) {
      for (final side in CustodySide.values) {
        final weekdays = [
          for (var weekday = 1; weekday <= daysInAWeek; weekday++)
            if (days[week * daysInAWeek + weekday - 1] == side) weekday,
        ];
        if (weekdays.isNotEmpty) {
          blocks.add(
            CustodyBlock(side: side, weekOffset: week, weekdays: weekdays),
          );
        }
      }
    }
    return CustodySchedule(
      pattern: pattern,
      startsOn: startsOn.weekStart,
      cycleWeeks: weeks,
      blocks: blocks,
      handoverMinute: handoverMinute,
    );
  }
}
