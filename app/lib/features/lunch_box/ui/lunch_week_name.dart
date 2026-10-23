import 'package:flutter/foundation.dart';

import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/lunch_board.dart';
import '../model/lunch_week.dart';

/// What a school week is called wherever a parent reads one — the week bar,
/// the budget meter, the board's spend line, *Plan my week* — so they always
/// know which week they are planning and pricing (lunch-box ADR-0019).
/// "This week" is the week being planned (`LunchWeek.planningFor`), which
/// from Saturday is the coming one (ADR-0003); one step either side is next
/// or last week, and anything further is named by its dates.
@immutable
final class LunchWeekName {
  const LunchWeekName._(this.week, this._weeksAway);

  factory LunchWeekName.of(LunchWeek week, {required LunchWeek planningWeek}) =>
      LunchWeekName._(week, planningWeek.weeksUntil(week));

  /// The week a board is on, from that board's today.
  factory LunchWeekName.ofBoard(LunchBoard board) =>
      LunchWeekName.of(board.week, planningWeek: board.planningWeek);

  /// By its dates alone, before anything says what today is.
  const LunchWeekName.dated(this.week) : _weeksAway = null;

  final LunchWeek week;

  /// Null when only the dates are known.
  final int? _weeksAway;

  /// Whether it has a name of its own rather than its dates.
  bool get isNear => switch (_weeksAway) {
    final weeks? => weeks.abs() <= 1,
    null => false,
  };

  /// On its own, as a heading: "This week", "Next week", "Last week", or
  /// "12 – 16 Oct".
  String get label => switch (_weeksAway) {
    0 => LunchCopy.thisWeek,
    1 => LunchCopy.nextWeekName,
    -1 => LunchCopy.lastWeek,
    _ => NestDates.schoolWeekRange(week.monday),
  };

  /// Inside a sentence: "this week", "next week", "last week", or "the week
  /// of 12 – 16 Oct".
  String get inSentence => switch (_weeksAway) {
    0 => LunchCopy.thisWeekInSentence,
    1 => LunchCopy.nextWeekInSentence,
    -1 => LunchCopy.lastWeekInSentence,
    _ => LunchCopy.weekOfDates(NestDates.schoolWeekRange(week.monday)),
  };
}
