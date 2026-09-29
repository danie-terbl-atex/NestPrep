/// Every capability the app can switch off without a migration (nestprep
/// verdict 003: each V2 item ships dark or on by one flag). A flag is named
/// here once; its field in the `appConfig/flags` document is [key].
///
/// Adding a flag is one line. Removing one is only safe once no installed
/// app reads it — an unknown field in the document is ignored, a missing one
/// is the safe default (`BE-10`).
enum FeatureFlag {
  // ---- calendar V2 (calendar ADR-0005, ADR-0006) ----
  snapSchoolLetter,
  mentalLoadView;

  /// The document field that switches it.
  String get key => name;
}
