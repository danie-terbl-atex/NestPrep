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

  // ---- lunch-box V2 (lunch-box ADR-0005 to ADR-0007) ----

  /// What is in the house, and planning the week from it (lunch-box
  /// ADR-0005).
  lunchPantry('lunchPantry'),

  /// What a box and a week cost, a weekly budget and cheaper swaps — premium
  /// as well (lunch-box ADR-0006).
  lunchBudget('lunchBudget'),

  /// A child choosing their own box from options a parent approved
  /// (lunch-box ADR-0007). The rules hold a kid to the approved options
  /// whatever this says; the switch only hides the screens.
  lunchKidPicks('lunchKidPicks'),

  // ---- calendar V2 (calendar ADR-0005, ADR-0006) ----

  /// Snap a school letter: the model reads it into events a parent confirms
  /// (calendar ADR-0005).
  snapSchoolLetter('snapSchoolLetter'),

  /// Who is handling what this week (calendar ADR-0006).
  mentalLoadView('mentalLoadView'),

  // ---- plan my week with AI (lunch-box ADR-0011) ----

  /// One tap plans the week's lunches, dinners and the shopping list —
  /// premium as well, and counted against the AI cap.
  planMyWeek('planMyWeek');

  const FeatureFlag(this.field);

  /// The boolean field in `appConfig/flags` that switches it.
  final String field;
}
