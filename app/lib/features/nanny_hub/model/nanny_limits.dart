/// Every limit the hub's rules enforce, in one place the screens read so a
/// person is stopped before the server says no (`FE-10`). The rules are the
/// authority; `nanny_limits_match_the_rules_test.dart` reads
/// `rules/firestore/household/nanny_hub.rules` and `storage.rules` and fails
/// when a number here drifts from the one there.
abstract final class NannyLimits {
  static const routines = 12;

  /// One step of a routine. The rules bound how many steps there are, not
  /// each one's words — they cannot loop over a list — so these two are the
  /// app's own, and the document's size limit is the server's backstop.
  static const routineLabel = 80;
  static const routineNote = 300;
  static const comfortItems = 30;
  static const careNote = 600;
  static const contactName = 60;
  static const contactNote = 200;
  static const address = 300;
  static const medicalAidScheme = 80;
  static const medicalAidPlan = 80;
  static const medicalAidNumber = 40;
  static const spotTitle = 80;
  static const spotNote = 400;
  static const ruleText = 300;
  static const checklistItems = 20;
  static const entryNote = 500;
  static const entryChildren = 10;
  static const ticks = 100;

  /// A photo's bytes after the app compressed it.
  static const photoBytes = 2 * 1024 * 1024;

  /// What a phone number may hold: digits, a leading plus, and the spaces,
  /// brackets and dashes people type to read it back.
  static final phonePattern = RegExp(r'^[+0-9 ()-]{3,20}$');

  /// How many of each record a listener reads (`BE-08`). More children,
  /// numbers, places or rules than any household has.
  static const cardListen = 20;
  static const contactListen = 30;
  static const guideListen = 40;
  static const ruleListen = 30;
  static const summaryListen = 20;
  static const openShiftListen = 5;
  static const entryListen = 200;

  // ---- V2 (nanny-hub ADR-0004 to ADR-0007) ----

  /// A photo update's caption, and how many children it can be about.
  static const photoCaption = 200;
  static const photoUpdateChildren = 10;
  static const photoUpdateListen = 60;

  static const pickupName = 60;
  static const pickupRelationship = 40;
  static const pickupIdNote = 200;
  static const pickupChildren = 10;
  static const schoolRunPlace = 80;
  static const pickupChangeNote = 200;
  static const pickupPeopleListen = 40;
  static const schoolRunListen = 70;
  static const pickupChangeListen = 60;

  static const bookingNote = 200;

  /// The longest shift a parent can book.
  static const bookingLength = Duration(hours: 24);
  static const bookingListen = 30;

  /// How long before a booked shift starts, and after it ends, the carer's
  /// access is open — time to reach the gate, and to hand over at the end.
  static const shiftGrace = Duration(minutes: 15);

  static const secretLabel = 60;
  static const secretValue = 120;
  static const secretNote = 200;
  static const secretListen = 20;
}
