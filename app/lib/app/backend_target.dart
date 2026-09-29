/// Which Firebase backend the build talks to, chosen at compile time with
/// `--dart-define=NESTPREP_BACKEND=emulator|cloud`. Cloud is the default, and
/// the emulator suite is what you opt into (foundation ADR-0011, amending
/// ADR-0003).
///
/// The consequence is deliberate and worth stating where it is set: a build that
/// passes no define reads and writes the one real household's data. Pass
/// `emulator` for anything destructive, and for the seeded sign-in shortcut,
/// which exists on that target only (accounts ADR-0002).
enum BackendTarget {
  emulator,
  cloud;

  static const defineName = 'NESTPREP_BACKEND';
  static const _defined = String.fromEnvironment(
    defineName,
    defaultValue: 'cloud',
  );

  static BackendTarget fromEnvironment() => fromName(_defined);

  /// Parses the define's value.
  ///
  /// Separate from [fromEnvironment] because `_defined` is a compile-time
  /// constant: under `flutter test` it is always the default, so the other
  /// branch and the refusal below are both unreachable through
  /// [fromEnvironment]. A typo in either would have
  /// surfaced as an app that throws on launch, and only on the build nobody
  /// runs locally. Named to match `MemberColor.fromName` and
  /// `MemberRole.fromName`.
  static BackendTarget fromName(String name) => switch (name) {
    'emulator' => BackendTarget.emulator,
    'cloud' => BackendTarget.cloud,
    _ => throw ArgumentError.value(
      name,
      defineName,
      'expected "emulator" or "cloud"',
    ),
  };
}
