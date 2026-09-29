/// Shift-only access' words (`FE-19`, nanny-hub ADR-0006): the shifts parents
/// book ahead, a carer kept to them, the house codes that open only inside
/// one, and what a carer sees between shifts.
abstract final class NannyBookingCopy {
  // The hub's places.
  static const bookings = 'Booked shifts';
  static const bookingsBody = 'Shifts booked ahead, and who sees what when';
  static const codes = 'House codes';
  static const codesBody = 'Alarm and gate codes, only during a shift';

  // Booked shifts.
  static const bookingsTitle = 'Booked shifts';
  static const carers = 'Carers';
  static const noCarersTitle = 'No carers yet';
  static const noCarersBody =
      'Invite your nanny or babysitter as a carer from the household screen, '
      'then book their shifts here.';
  static const shiftOnly = 'Only during booked shifts';
  static String shiftOnlyFor(String name) =>
      '$name sees the household only during booked shifts';
  static const shiftOnlyOn =
      'Sees the household only from 15 minutes before a booked shift until 15 '
      'minutes after it.';
  static const shiftOnlyOff = 'Sees what you shared with them at any time.';
  static const shiftOnlyAdminOnly = 'An admin can change this.';
  static const upcoming = 'Coming up';
  static const noBookingsTitle = 'Nothing booked';
  static const noBookingsBody =
      'Book a shift and the carer sees it here. House codes open only during '
      'one.';
  static const book = 'Book a shift';
  static const bookTitle = 'Book a shift';
  static const who = 'Who is looking after the children?';
  static const day = 'Day';
  static String startsAt(String time) => 'Starts at $time';
  static String endsAt(String time) => 'Ends at $time';
  static const endsNextDay = 'Ends the next morning';
  static const note = 'A note for the carer (optional)';
  static const noteHint = 'School pick-up at 14:30, then home';
  static const tooLong = 'A shift can be at most 24 hours.';
  static const inThePast = 'That shift has already ended. Pick a later time.';
  static const confirmBook = 'Book it';
  static const cancel = 'Cancel this shift';
  static const cancelConfirm = 'Cancel this shift?';
  static const cancelBody =
      'The carer’s access for it closes straight away, and the house codes '
      'with it.';
  static const cancelAction = 'Cancel the shift';
  static const keep = 'Keep it';
  static String when(String day, String from, String to) => '$day, $from – $to';
  static const onNow = 'On now';
  static const yourShifts = 'Your booked shifts';
  static const yourShiftsEmpty =
      'No shifts booked for you yet. A parent books them here.';

  // Between shifts: what a carer kept to their shifts sees.
  static const offShiftTitle = 'See you at your next shift';
  static String offShiftNext(String when) => 'Your next shift: $when.';
  static String opensAt(String time) =>
      'The household opens for you at $time, 15 minutes before it starts.';
  static const offShiftNone =
      'No shift is booked for you. When a parent books one, the household '
      'opens for it — from 15 minutes before it starts.';
  static const checkAgain = 'Check again';
  static String openUntil(String time) =>
      'You can see the household until $time, 15 minutes after your shift.';

  // House codes.
  static const codesTitle = 'House codes';
  static const codesFamilyNote =
      'Carers see these only from 15 minutes before a shift booked for them '
      'until 15 minutes after it. They are fetched fresh each time.';
  static String codesOpenUntil(String time) => 'Shown until $time.';
  static const codesClosedTitle = 'Codes open during your shift';
  static String codesClosedNext(String when) =>
      'Next shift: $when. The codes open 15 minutes before it.';
  static const codesClosedNone =
      'No shift is booked for you, so the codes stay closed. Ask a parent.';
  static const codesNeedSignal =
      'Codes are fetched fresh, so they need a signal. Open them before you '
      'leave home.';
  static const noCodesTitle = 'No codes yet';
  static const noCodesBody =
      'Add the alarm code, the gate code or where the spare key is. Carers '
      'see them only during a booked shift.';
  static const addCode = 'Add a code';
  static const editCode = 'Change this code';
  static const codeLabel = 'What it is for';
  static const codeLabelHint = 'Alarm';
  static const codeValue = 'The code';
  static const codeValueHint = '4821, then the tick';
  static const codeNote = 'Anything else (optional)';
  static const codeNoteHint = 'Panel is behind the front door';
  static const saveCode = 'Save';
  static const removeCode = 'Remove this code';
  static const removeCodeConfirm = 'Remove this code?';
}
