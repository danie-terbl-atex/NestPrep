import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import 'custody_side.dart';

part 'custody_schedule.freezed.dart';
part 'custody_schedule.g.dart';

/// Which preset a schedule was made from. The blocks are the truth; the
/// pattern is the name the screens give them.
enum CustodyPattern { alternatingWeeks, twoTwoThree, everyOtherWeekend, custom }

/// One home's days in one week of the cycle (household ADR-0004).
@freezed
abstract class CustodyBlock with _$CustodyBlock {
  const factory CustodyBlock({
    required CustodySide side,
    required int weekOffset,
    required List<int> weekdays,
  }) = _CustodyBlock;

  factory CustodyBlock.fromJson(Map<String, Object?> json) =>
      _$CustodyBlockFromJson(json);
}

/// A parenting schedule: a cycle of one to four weeks from a Monday, every day
/// of it belonging to one home (household ADR-0004).
///
/// Each block **is** a recurrence rule — weekly, every `cycleWeeks` weeks, on
/// its weekdays, first occurring in its week of the cycle — so the days are
/// expanded by the same `expandOccurrences` todos and the calendar read
/// (foundation ADR-0005), never by arithmetic of this feature's own.
@freezed
abstract class CustodySchedule with _$CustodySchedule {
  const factory CustodySchedule({
    @JsonKey(unknownEnumValue: CustodyPattern.custom)
    required CustodyPattern pattern,

    /// The Monday the cycle's first week starts on.
    @CalendarDateConverter() required CalendarDate startsOn,
    required int cycleWeeks,
    required List<CustodyBlock> blocks,

    /// When the child changes homes, in minutes after midnight in the
    /// household's own time. Null is "some time that day".
    int? handoverMinute,
  }) = _CustodySchedule;

  const CustodySchedule._();

  factory CustodySchedule.fromJson(Map<String, Object?> json) =>
      _$CustodyScheduleFromJson(json);

  static const maxCycleWeeks = 4;

  /// Each block as the recurrence model's rule, with the day it first falls.
  List<({CustodySide side, CalendarDate firstDate, RecurrenceRule rule})>
  get rules => [
    for (final block in blocks)
      (
        side: block.side,
        firstDate: startsOn.addDays(block.weekOffset * 7),
        rule: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: cycleWeeks,
          weekdays: block.weekdays,
        ),
      ),
  ];

  /// The home on each day of the cycle, in order from its first Monday — what
  /// the preview strip and the custom editor draw. A day no block names is
  /// null, which only a schedule the server would refuse can have.
  List<CustodySide?> get cycle {
    final days = List<CustodySide?>.filled(cycleWeeks * 7, null);
    for (final block in blocks) {
      for (final weekday in block.weekdays) {
        final index = block.weekOffset * 7 + weekday - 1;
        if (index >= 0 && index < days.length) days[index] = block.side;
      }
    }
    return days;
  }

  /// Whether every day of the cycle belongs to exactly one home — the server's
  /// check, made before sending so the form never offers what it would refuse.
  bool get isComplete {
    if (cycleWeeks < 1 || cycleWeeks > maxCycleWeeks) return false;
    if (startsOn.weekday != DateTime.monday) return false;
    final seen = <int>{};
    for (final block in blocks) {
      if (block.weekOffset < 0 || block.weekOffset >= cycleWeeks) return false;
      for (final weekday in block.weekdays) {
        if (weekday < 1 || weekday > 7) return false;
        if (!seen.add(block.weekOffset * 7 + weekday)) return false;
      }
    }
    return seen.length == cycleWeeks * 7;
  }
}
