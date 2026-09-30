/// What the backend said about a session this device restored from disk,
/// before the app trusts it (accounts ADR-0008).
enum SessionCheck {
  /// The backend refreshed the token: the session is live.
  accepted,

  /// The backend refused the token for good — the account was deleted or
  /// disabled, the password changed, the session revoked, or it was issued by
  /// another backend. Signing in again is the only cure.
  rejected,

  /// The backend could not be asked — offline, or too slow to answer. The
  /// cached session is kept, because signing somebody out for being offline
  /// would break the app exactly where it is meant to work.
  unverified,
}
