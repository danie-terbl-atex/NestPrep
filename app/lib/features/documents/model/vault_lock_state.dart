/// Where the vault's lock stands (documents ADR-0003).
enum VaultLockState {
  locked,

  /// The device's own prompt is up.
  unlocking,
  unlocked,
}

/// What the device said when asked to unlock, in the words the lock screen
/// needs. Kept apart from `AppFailure` because none of these is the backend
/// saying no — every one is about this phone.
enum UnlockOutcome {
  unlocked,

  /// The person backed out of the prompt. Not a failure; nothing is said.
  cancelled,

  /// The phone has no PIN, pattern, passcode or biometrics at all. The vault
  /// does not open on it — a lock that can be skipped is no lock.
  noScreenLock,

  /// Too many wrong tries; the phone makes them wait.
  lockedOut,

  /// The phone could not show its prompt, for a reason nobody can act on.
  unavailable,
}
