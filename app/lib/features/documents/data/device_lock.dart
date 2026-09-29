import '../model/vault_lock_state.dart';

/// The phone's own lock — biometrics, with its PIN, pattern or passcode behind
/// them (documents ADR-0003).
///
/// Behind an interface because a widget test has no fingerprint, and because
/// "this phone has no screen lock" is a state the lock screen has to say
/// something true about (`FE-08`).
abstract interface class DeviceLock {
  /// Asks the person to prove it is them. [reason] is shown in the system
  /// prompt.
  Future<UnlockOutcome> unlock(String reason);
}
