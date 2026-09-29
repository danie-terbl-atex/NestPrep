/// Every V2 capability that can be switched off without a migration
/// (foundation ADR-0014), and the field that switches it in
/// `appConfig/flags`.
///
/// One enum for the whole app, so there is one place to see what is
/// switchable. The Functions read the same fields from
/// `functions/src/shared/feature_flags.ts`, and `feature_flags.test.ts` there
/// reads this file and fails if the two lists differ.
///
/// A V2 feature adds one value here, one field on the server list, and reads
/// it through `FeatureFlagsController.isOn`.
enum FeatureFlag {
  /// Share one document by an expiring link (documents ADR-0006).
  documentShareLinks('documentShareLinks'),

  /// Keep chosen documents on the phone, encrypted (documents ADR-0007).
  documentOfflineCopies('documentOfflineCopies'),

  /// Snap a school letter into proposed events (calendar ADR-0005).
  snapSchoolLetter('snapSchoolLetter'),

  /// The shared week: who is handling what (calendar ADR-0006).
  mentalLoadView('mentalLoadView'),

  /// A child in two homes: shared schedules and handovers (household
  /// ADR-0004).
  coParenting('coParenting'),

  // ---- nanny hub V2 (nanny-hub ADR-0004 to ADR-0007) ----

  /// A carer's photos to the parents during a shift (nanny-hub ADR-0004).
  nannyPhotoUpdates('nannyPhotoUpdates'),

  /// Who may collect each child, and the school run (nanny-hub ADR-0005).
  nannyPickups('nannyPickups'),

  /// Booked shifts, shift-only carers and the house codes (nanny-hub
  /// ADR-0006). The rules enforce a shift-only carer's window whatever this
  /// says; the switch only hides the screens that set one up.
  nannyShiftOnly('nannyShiftOnly'),

  /// The emergency sheet and child cards saved for no signal (nanny-hub
  /// ADR-0007).
  nannyOffline('nannyOffline'),

  /// Give a month, get a month (subscriptions ADR-0002).
  referralRewards('referralRewards');

  const FeatureFlag(this.field);

  /// The boolean field in `appConfig/flags` that switches it.
  final String field;
}
