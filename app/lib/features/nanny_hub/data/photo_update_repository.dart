import '../model/photo_update.dart';

/// Photo updates as Firestore holds them (nanny-hub ADR-0004). Sending one
/// writes the document notifications pushes from — `delivery.state` starts
/// `pending` — and the parents' feed hears it at once.
abstract interface class PhotoUpdateRepository {
  /// One shift's photos, newest first, bounded (`BE-08`).
  Stream<List<PhotoUpdate>> watchUpdates({
    required String householdId,
    required String shiftId,
  });

  /// Sends an already-stored photo to the parents.
  Future<void> send(PhotoUpdateWrite write);

  Future<void> remove({
    required String householdId,
    required String shiftId,
    required String updateId,
  });
}

/// One photo update, by one member, on one shift.
typedef PhotoUpdateWrite = ({
  String householdId,
  String shiftId,
  String byMemberId,
  String photoId,
  String? caption,
  List<String> childIds,
});
