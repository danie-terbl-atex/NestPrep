/// Every word a helper's clock says (home-care ADR-0007, `FE-19`) — exported
/// through `home_care_copy.dart`.
abstract final class HomeCareShiftCopy {
  static const shifts = 'Shifts';
  static const subtitle = 'When each shift started and ended';

  static const readyTitle = 'Ready when you are';
  static const readyBody = 'Clock in when you start, and out when you leave.';
  static const startShift = 'Start shift';
  static const endShift = 'End shift';
  static const onShiftTitle = 'You are on shift';
  static String since(String time) => 'Since $time';
  static const justNow = 'Just now';

  static const endTitle = 'End your shift?';
  static String endBody(String time) =>
      'You started at $time. This clocks you out now.';
  static String endForTitle(String name) => 'End $name’s shift?';
  static const endForBody =
      'This clocks them out now, not at the time they left.';
  static const cancel = 'Not yet';

  static const onNow = 'On shift now';
  static const past = 'Past shifts';
  static String times(String start, String end) => '$start – $end';
  static String dayAndTimes(String day, String times) => '$day · $times';
  static const atTheFrame = 'Frame';

  static String length(Duration length) {
    final hours = length.inHours;
    final minutes = length.inMinutes.remainder(60);
    if (hours == 0) return '$minutes min';
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }

  static const lockedOpenBody =
      'Home care is locked, but a shift that is still open can be ended here.';

  static const emptyTitle = 'No shifts yet';
  static const emptyBody =
      'When a helper starts a shift, in the app or at a frame, it shows here.';
  static const emptyHelperBody =
      'Start a shift from your cleaning jobs and it shows here.';
}
