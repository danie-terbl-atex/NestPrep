/// The users the emulator's Auth is seeded with, so a local run and a
/// hand-driven test can sign in without Google (accounts ADR-0001). They are
/// offered wherever the backend is `BackendTarget.emulator` — a release build
/// included — because that target cannot reach real data; this password
/// guards nothing but a local database (`ENG-18`).
///
/// `functions/tools/seed-emulator.mjs` creates exactly these, under fixed
/// uids and in one demo household, so each button is the same account in the
/// same household on every device and after every restart (foundation
/// ADR-0018).
class EmulatorAccount {
  const EmulatorAccount({
    required this.label,
    required this.email,
    required this.displayName,
  });

  final String label;
  final String email;
  final String displayName;

  /// One password for every seeded user, because there is nothing to protect.
  static const password = 'nestprep';

  static const all = [
    EmulatorAccount(
      label: 'Parent',
      email: 'parent@nestprep.test',
      displayName: 'Sam Parent',
    ),
    EmulatorAccount(
      label: 'Second parent',
      email: 'partner@nestprep.test',
      displayName: 'Alex Parent',
    ),
    EmulatorAccount(
      label: 'Helper',
      email: 'helper@nestprep.test',
      displayName: 'Thandi Helper',
    ),
  ];
}
