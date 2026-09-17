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

  static BackendTarget fromEnvironment() => switch (_defined) {
    'emulator' => BackendTarget.emulator,
    'cloud' => BackendTarget.cloud,
    _ => throw ArgumentError.value(
      _defined,
      defineName,
      'expected "emulator" or "cloud"',
    ),
  };
}
