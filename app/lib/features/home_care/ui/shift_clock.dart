import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../model/shift/helper_shift.dart';

/// A shift's instants as the household reads them (`ENG-21`): the time on the
/// household's wall clock, and the day it falls on.
extension ShiftClock on HouseholdClock {
  /// "07:32", or "Just now" while the server has not stamped it yet.
  String shiftTime(DateTime? instant) => instant == null
      ? HomeCareShiftCopy.justNow
      : NestDates.timeOfDay(minutesOfDay(instant));

  /// "Today · 07:32 – 16:05".
  String shiftSpan(HelperShift shift) {
    final started = shift.startedAt;
    final times = HomeCareShiftCopy.times(
      shiftTime(started),
      shiftTime(shift.endedAt),
    );
    return started == null
        ? times
        : HomeCareShiftCopy.dayAndTimes(
            NestDates.relative(dateOf(started), today),
            times,
          );
  }
}
