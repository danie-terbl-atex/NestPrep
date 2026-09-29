/// How a connection's last sync went. Each is a sentence on the screen, never
/// a code (`FE-09`); the server's `CONNECTION_STATUSES` is the other half.
enum ConnectionStatus {
  connected,

  /// The person took NestPrep's access away, or it expired unused.
  revoked,

  /// The provider could not be reached; the next sync tries again.
  unreachable,

  /// A calendar link that no longer leads to a calendar.
  notACalendar,

  /// The provider is not set up on this deployment.
  notConfigured;

  bool get isHealthy => this == connected;
}
