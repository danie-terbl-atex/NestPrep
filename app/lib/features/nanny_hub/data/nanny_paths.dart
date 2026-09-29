/// The hub's collection names, in one place both Firestore repositories read
/// (`ENG-01`). `nanny_hub.rules` and `endNannyShift` spell them the same way.
abstract final class NannyPaths {
  static const households = 'households';
  static const cards = 'nannyChildCards';
  static const contacts = 'nannyContacts';
  static const home = 'nannyHome';
  static const guide = 'nannyGuide';
  static const rules = 'nannyRules';
  static const checklists = 'nannyChecklists';
  static const shifts = 'nannyShifts';
  static const entries = 'entries';
  static const summaries = 'nannyShiftSummaries';

  // V2 (nanny-hub ADR-0004 to ADR-0007).
  static const photoUpdates = 'photoUpdates';
  static const pickupPeople = 'nannyPickupPeople';
  static const schoolRuns = 'nannySchoolRuns';
  static const pickupChanges = 'nannyPickupChanges';
  static const bookings = 'nannyBookings';
  static const passes = 'nannyShiftPasses';
  static const secrets = 'nannySecrets';
}
