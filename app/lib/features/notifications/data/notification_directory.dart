/// What happened to a test push, in the words the settings screen chooses
/// from (notifications ADR-0003). The server's `TestOutcome` spells the same.
enum TestPushOutcome {
  sent,
  noDevice,
  failed,
  alreadySent;

  /// An answer this build does not know is treated as not delivered.
  static TestPushOutcome fromName(Object? name) =>
      values.where((value) => value.name == name).firstOrNull ?? failed;
}

/// The one notifications callable: a push to the caller's own phones, through
/// exactly the path every other notification takes.
abstract interface class NotificationDirectory {
  Future<TestPushOutcome> sendTestNotification(String householdId);
}
