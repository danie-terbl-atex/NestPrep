/// Tells the server that this account opened the app with a household — the
/// whole of what makes a member *active* (product-analytics ADR-0001).
///
/// Only the household is sent. Which member that is, and which week, the
/// server works out from the token and the household's own membership, so this
/// cannot count anybody else.
abstract interface class ActivityRecorder {
  Future<void> recordActivity(String householdId);
}
