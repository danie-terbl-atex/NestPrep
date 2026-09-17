/// The users the emulator's Auth is seeded with, so a local run and a
/// hand-driven test can sign in without Google's OAuth configuration (accounts
/// ADR-0001). These exist only where `BackendTarget.emulator` does; the cloud
/// project never enables email-and-password, and this password guards nothing
/// that is not a throwaway local database (`ENG-18`).
///
/// `functions/tools/seed-emulator.mjs` creates exactly these.
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
