/// Which Firebase backend the build talks to, chosen at compile time with
/// `--dart-define=NESTPREP_BACKEND=emulator|cloud`. Emulator is the default so a
/// clone runs with no cloud project (foundation ADR-0003).
enum BackendTarget {
  emulator,
  cloud;

  static const defineName = 'NESTPREP_BACKEND';
  static const _defined = String.fromEnvironment(
    defineName,
    defaultValue: 'emulator',
  );

  static BackendTarget fromEnvironment() => fromName(_defined);

  /// Parses the define's value.
  ///
  /// Separate from [fromEnvironment] because `_defined` is a compile-time
  /// constant: under `flutter test` it is always `'emulator'`, so the `'cloud'`
  /// branch — the one every real cloud build takes — and the refusal below are
  /// both unreachable through [fromEnvironment]. A typo in either would have
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
