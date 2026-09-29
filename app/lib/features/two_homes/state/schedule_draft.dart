import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import '../model/custody_presets.dart';
import '../model/custody_schedule.dart';
import '../model/custody_side.dart';

/// A schedule being chosen — on the way to making a code, or as a suggested
/// change to a live link (household ADR-0004). One draft, one editor, so the
/// two places a schedule is picked cannot drift apart (`ENG-01`).
///
/// Sides are the link's own: `a` made the code, `b` accepted it. The editor
/// names them.
final class ScheduleDraft extends ChangeNotifier {
  ScheduleDraft({required CalendarDate today})
    : _startsOn = today.weekStart,
      _custom = _fortnightFrom(
        CustodyPresets.alternatingWeeks(
          startsOn: today.weekStart,
          first: CustodySide.a,
        ),
      );

  /// A draft that is exactly [schedule], for suggesting a change to it: the
  /// same first Monday — so the fortnight keeps its phase and nothing moves
  /// until somebody changes something — and the preset's own choices found
  /// again from its days. A schedule no preset makes opens as the custom
  /// fortnight it is.
  ScheduleDraft.from(CustodySchedule schedule)
    : _startsOn = schedule.startsOn,
      _handoverMinute = schedule.handoverMinute,
      _custom = _fortnightFrom(schedule) {
    final found = _presetMaking(schedule);
    _pattern = found?.pattern ?? CustodyPattern.custom;
    _first = found?.first ?? CustodySide.a;
    _switchWeekday = found?.switchWeekday ?? DateTime.friday;
  }

  CustodyPattern _pattern = CustodyPattern.alternatingWeeks;
  CalendarDate _startsOn;
  CustodySide _first = CustodySide.a;
  int _switchWeekday = DateTime.friday;
  int? _handoverMinute;
  List<CustodySide> _custom;

  CustodyPattern get pattern => _pattern;
  CalendarDate get startsOn => _startsOn;

  /// Who has the child from the first switch — or, for every other weekend,
  /// whose weekdays they are.
  CustodySide get first => _first;
  int get switchWeekday => _switchWeekday;
  int? get handoverMinute => _handoverMinute;

  /// The custom fortnight, one home per day from the first Monday.
  List<CustodySide> get custom => List.unmodifiable(_custom);

  /// The schedule these choices make.
  CustodySchedule get schedule => switch (_pattern) {
    CustodyPattern.alternatingWeeks => CustodyPresets.alternatingWeeks(
      startsOn: _startsOn,
      first: _first,
      switchWeekday: _switchWeekday,
      handoverMinute: _handoverMinute,
    ),
    CustodyPattern.twoTwoThree => CustodyPresets.twoTwoThree(
      startsOn: _startsOn,
      first: _first,
      handoverMinute: _handoverMinute,
    ),
    CustodyPattern.everyOtherWeekend => CustodyPresets.everyOtherWeekend(
      startsOn: _startsOn,
      primary: _first,
      handoverMinute: _handoverMinute,
    ),
    CustodyPattern.custom => CustodyPresets.fromCycle(
      pattern: CustodyPattern.custom,
      startsOn: _startsOn,
      days: _custom,
      handoverMinute: _handoverMinute,
    ),
  };

  void choosePattern(CustodyPattern pattern) {
    if (pattern == _pattern) return;
    // Opening the custom grid starts from what was showing, so tapping a day
    // or two adjusts a preset rather than starting from nothing.
    if (pattern == CustodyPattern.custom) _custom = _fortnightFrom(schedule);
    _pattern = pattern;
    notifyListeners();
  }

  void chooseStart(CalendarDate date) {
    final monday = date.weekStart;
    if (monday == _startsOn) return;
    _startsOn = monday;
    notifyListeners();
  }

  void chooseFirst(CustodySide side) {
    if (side == _first) return;
    _first = side;
    notifyListeners();
  }

  void chooseSwitchWeekday(int weekday) {
    if (weekday == _switchWeekday) return;
    _switchWeekday = weekday;
    notifyListeners();
  }

  void chooseHandoverMinute(int? minute) {
    if (minute == _handoverMinute) return;
    _handoverMinute = minute;
    notifyListeners();
  }

  /// Moves one day of the custom fortnight to the other home.
  void flipDay(int index) {
    if (index < 0 || index >= _custom.length) return;
    _custom = [..._custom]..[index] = _custom[index].other;
    notifyListeners();
  }

  /// The preset and choices that make exactly [schedule]'s days, if any do.
  static ({CustodyPattern pattern, CustodySide first, int switchWeekday})?
  _presetMaking(CustodySchedule schedule) {
    final days = schedule.cycle;
    for (final first in CustodySide.values) {
      final candidates = [
        for (var weekday = 1; weekday <= 7; weekday++)
          (
            pattern: CustodyPattern.alternatingWeeks,
            first: first,
            switchWeekday: weekday,
            made: CustodyPresets.alternatingWeeks(
              startsOn: schedule.startsOn,
              first: first,
              switchWeekday: weekday,
            ),
          ),
        (
          pattern: CustodyPattern.twoTwoThree,
          first: first,
          switchWeekday: DateTime.friday,
          made: CustodyPresets.twoTwoThree(
            startsOn: schedule.startsOn,
            first: first,
          ),
        ),
        (
          pattern: CustodyPattern.everyOtherWeekend,
          first: first,
          switchWeekday: DateTime.friday,
          made: CustodyPresets.everyOtherWeekend(
            startsOn: schedule.startsOn,
            primary: first,
          ),
        ),
      ];
      for (final candidate in candidates) {
        if (candidate.pattern == schedule.pattern &&
            listEquals(candidate.made.cycle, days)) {
          return (
            pattern: candidate.pattern,
            first: candidate.first,
            switchWeekday: candidate.switchWeekday,
          );
        }
      }
    }
    return null;
  }

  /// A schedule as a fortnight, one home per day: a one-week cycle repeated,
  /// a longer one cut to its first two weeks.
  static List<CustodySide> _fortnightFrom(CustodySchedule schedule) {
    final cycle = schedule.cycle;
    return [
      for (var day = 0; day < CustodyPresets.fortnight * 7; day++)
        (cycle.isEmpty ? null : cycle[day % cycle.length]) ?? CustodySide.a,
    ];
  }
}
