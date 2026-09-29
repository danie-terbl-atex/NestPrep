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

  // ---- home care V2 (home-care ADR-0004 to ADR-0006) ----

  /// Recurring checklists per room, and the helper's today's rooms
  /// (home-care ADR-0004).
  homeCareRoutines('homeCareRoutines'),

  /// Each product's stock level, and a low one onto the grocery list
  /// (home-care ADR-0005).
  homeCareStock('homeCareStock'),

  /// The helper's own language for her jobs, and read-aloud (home-care
  /// ADR-0006).
  homeCareHelperLanguage('homeCareHelperLanguage');

  const FeatureFlag(this.field);

  /// The boolean field in `appConfig/flags` that switches it.
  final String field;
}
