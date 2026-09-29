/// Who may collect each child and the school-run week (`FE-19`, nanny-hub
/// ADR-0005) — the words a carer reads at the door, kept apart from
/// `NannyCopy` so neither file grows past what anybody can read (`ENG-05`).
abstract final class NannyPickupCopy {
  // The hub's row.
  static const place = 'School run and pickups';
  static const placeBody = 'Who may collect each child, and the week';

  // The pickups screen.
  static const title = 'Pickups';
  static const today = 'Today’s school run';
  static String todayOn(String day) => 'Today, $day';
  static const noChildren =
      'Children appear here once they are in the household. A parent adds '
      'them from the household screen.';
  static const noRunToday = 'No school run today';
  static const nobodyToday = 'Nobody collects today';
  static const changedToday = 'Changed for today';
  static const checkDoor = 'Door check';
  static const checkDoorHint =
      'Someone at the door? Check they are on the list.';

  static const whoMayCollect = 'Who may collect';
  static const addPerson = 'Add a person';
  static String nobodyListed(String child) =>
      'Nobody is listed for $child yet. Until a parent adds someone, '
      '$child is released to nobody.';
  static const addPersonHint =
      'Add each adult who may collect — with a photo, so a carer knows them '
      'at the door.';

  static const week = 'The school-run week';
  static const notSet = 'Not set';
  static const noWeekYet = 'No usual school run yet.';

  static const changes = 'Changes coming up';
  static const addChange = 'Add a change for a day';
  static const noChanges =
      'No changes. When Gogo collects on one day, or there is no school, add '
      'it here — it wins over the usual week.';

  static String weekdayName(int weekday) => switch (weekday) {
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wednesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday',
    _ => 'Sunday',
  };

  static String at(String time) => 'at $time';

  // The person sheet.
  static const editPerson = 'Change this person';
  static const name = 'Their name';
  static const nameHint = 'Thandi Mokoena';
  static const relationship = 'Who they are to the family';
  static const relationshipHint = 'Gogo, Uncle, Lebo’s mom';
  static const idNote = 'How to be sure it is them (optional)';
  static const idNoteHint = 'Shows her ID; drives a white Polo';
  static const phone = 'Phone (optional)';
  static const phoneHint = '082 555 0199';
  static const phoneNotValid = 'Use digits, spaces and a leading +.';
  static const mayCollect = 'Who may they collect?';
  static const removePersonConfirm =
      'Remove this person? A carer will no longer release a child to them.';

  // The run and change sheets.
  static String runTitle(String child, int weekday) =>
      '$child on ${weekdayName(weekday)}s';
  static const whoCollects = 'Who collects';
  static const noCollectorsYet =
      'Add the people who may collect first — or choose one of the '
      'household.';
  static const nobodyCollects = 'Nobody — no school run';
  static const time = 'Time';
  static const noTime = 'Any time';
  static const pickTime = 'Choose a time';
  static const placeLabel = 'Where (optional)';
  static const placeHint = 'Oakwood Primary, the side gate';
  static const removeRun = 'Clear this day';
  static const changeTitle = 'A change for one day';
  static const editChange = 'Change this day';
  static const whichChild = 'Which child';
  static const date = 'Which day';
  static const note = 'A note (optional)';
  static const noteHint = 'Swimming gala — collect at the pool';
  static const removeChangeConfirm = 'Remove this change?';

  // The door check.
  static const checkTitle = 'Who is at the door?';
  static String checkIntro(String child) =>
      'Only hand $child to somebody on this list. Look at the photo, and '
      'check how to be sure it is them.';
  static const expectedToday = 'Expected today';
  static String expectedAt(String time) => 'Expected today at $time';
  static const household = 'Of the household';
  static String callPerson(String name) => 'Call $name';
  static String notOnListTitle(String child) =>
      'Not on this list? Do not release $child.';
  static String notOnListBody(String child) =>
      'Keep $child with you, inside, and call a parent now.';
  static String nobodyAllowedTitle(String child) =>
      'Nobody may collect $child. Do not release $child.';
  static String nobodyAllowedBody(String child) =>
      'No parent has listed anybody who may collect $child. Keep $child with '
      'you and call a parent.';
  static String callParent(String name) => 'Call $name';
  static const noParentNumber =
      'No parent’s number is on the emergency sheet — open it for the '
      'public numbers.';
  static const openEmergency = 'Open the emergency sheet';
  static const childGoneTitle = 'This child is not here';
  static const childGoneBody =
      'They may have been removed. Go back to the hub.';
  static String photoOf(String name) => 'Photo of $name';
}
