import '../model/assistant_activity.dart';
import '../model/assistant_connection.dart';

/// What *Connected assistants* reads and writes in Firestore (assistants
/// ADR-0003, ADR-0005). A Function writes the connections and the activity;
/// a member only reads them, deletes a connection, and — family only —
/// switches the household's assistants off and on.
abstract interface class AssistantRepository {
  /// Every connection in the household, or with [ownerUid] only that
  /// account's — what the rules let somebody who is not family list.
  Stream<List<AssistantConnection>> watchConnections(
    String householdId, {
    String? ownerUid,
  });

  /// Recent changes assistants made, or with [memberId] only those made as
  /// that profile — what the rules let somebody who is not family list.
  Stream<List<AssistantActivity>> watchActivity(
    String householdId, {
    String? memberId,
  });

  /// Whether assistants may work in the household. No settings document
  /// means they may.
  Stream<bool> watchAllowed(String householdId);

  /// Deletes the grant, which is what disconnecting is. Refused rather than
  /// queued while the server cannot be reached, so a connection is never
  /// shown as gone while it still works.
  Future<void> disconnect({
    required String householdId,
    required String connectionId,
  });

  /// Refused rather than queued while the server cannot be reached, for the
  /// same reason as [disconnect].
  Future<void> setAllowed({
    required String householdId,
    required bool allowed,
    required String memberId,
  });

  /// A member connects one or two assistants, never dozens.
  static const connectionLimit = 50;

  /// Enough to show each connection's last few changes.
  static const activityLimit = 100;
}
