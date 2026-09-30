import '../shared/copy/app_copy.dart';
import 'backend_target.dart';

/// One fixed account the sign-in screen offers as a single tap.
class SeededAccount {
  const SeededAccount({required this.label, required this.email});

  final String label;
  final String email;
}

/// The one-tap sign-in shortcut, and the only place that decides whether a
/// build has one (accounts ADR-0002, foundation ADR-0018 and ADR-0019):
///
/// - **emulator target** — the three users `functions/tools/seed-emulator.mjs`
///   creates under fixed uids. Their password guards nothing but a local
///   database, so it is a constant here (`ENG-18`).
/// - **cloud target built with `NESTPREP_DEMO_LOGINS=true`** — the live demo
///   accounts `functions/tools/seed-cloud-demo.mjs` creates in the real
///   project. Their addresses and password come only from the defines
///   (`--dart-define-from-file=demo_logins.json`, a gitignored file), so
///   nothing about them is in the source.
///
/// Any other build — every store build — has none, and the sign-in screen
/// renders nothing for it. The guards are compile-time constants, so the demo
/// branch is dead code in a build without the define.
class SeededSignIn {
  const SeededSignIn._({
    required this.hint,
    required this.password,
    required this.accounts,
  });

  /// The line above the buttons, saying which kind of shortcut this is.
  final String hint;
  final String password;
  final List<SeededAccount> accounts;

  static const _demoLogins = bool.fromEnvironment('NESTPREP_DEMO_LOGINS');
  static const _demoPassword = String.fromEnvironment('NESTPREP_DEMO_PASSWORD');

  static const _emulator = SeededSignIn._(
    hint: AppCopy.signInEmulatorHint,
    password: 'nestprep',
    accounts: [
      SeededAccount(
        label: AppCopy.signInAsParent,
        email: 'parent@nestprep.test',
      ),
      SeededAccount(
        label: AppCopy.signInAsPartner,
        email: 'partner@nestprep.test',
      ),
      SeededAccount(
        label: AppCopy.signInAsHelper,
        email: 'helper@nestprep.test',
      ),
    ],
  );

  static const _demoAccounts = [
    SeededAccount(
      label: AppCopy.signInAsParent,
      email: String.fromEnvironment('NESTPREP_DEMO_EMAIL_PARENT'),
    ),
    SeededAccount(
      label: AppCopy.signInAsPartner,
      email: String.fromEnvironment('NESTPREP_DEMO_EMAIL_PARTNER'),
    ),
    SeededAccount(
      label: AppCopy.signInAsHelper,
      email: String.fromEnvironment('NESTPREP_DEMO_EMAIL_HELPER'),
    ),
    SeededAccount(
      label: AppCopy.signInAsNanny,
      email: String.fromEnvironment('NESTPREP_DEMO_EMAIL_NANNY'),
    ),
    SeededAccount(
      label: AppCopy.signInAsGran,
      email: String.fromEnvironment('NESTPREP_DEMO_EMAIL_GRAN'),
    ),
  ];

  /// The shortcut this build offers on [target], or null for none.
  static SeededSignIn? forBuild(BackendTarget target) {
    if (target == BackendTarget.emulator) return _emulator;
    if (!_demoLogins || _demoPassword.isEmpty) return null;
    final accounts = [
      for (final account in _demoAccounts)
        if (account.email.isNotEmpty) account,
    ];
    if (accounts.isEmpty) return null;
    return SeededSignIn._(
      hint: AppCopy.signInDemoHint,
      password: _demoPassword,
      accounts: accounts,
    );
  }
}
