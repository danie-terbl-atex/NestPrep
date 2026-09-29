import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/nanny_limits.dart';
import '../model/photo_update.dart';
import 'nanny_paths.dart';
import 'photo_update_repository.dart';

final class FirestorePhotoUpdateRepository implements PhotoUpdateRepository {
  FirestorePhotoUpdateRepository(this._firestore);

  /// What a new update's `delivery` says until notifications has pushed it —
  /// the field notifications triggers on (nanny-hub ADR-0004).
  static const pendingDelivery = {'state': 'pending'};

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _updates(
    String householdId,
    String shiftId,
  ) => _firestore
      .collection(NannyPaths.households)
      .doc(householdId)
      .collection(NannyPaths.shifts)
      .doc(shiftId)
      .collection(NannyPaths.photoUpdates);

  @override
  Stream<List<PhotoUpdate>> watchUpdates({
    required String householdId,
    required String shiftId,
  }) =>
      typedCollection(
            _updates(householdId, shiftId),
            fromJson: PhotoUpdate.fromJson,
            toJson: (_) => throw UnsupportedError('written field by field'),
          )
          .orderBy('createdAt', descending: true)
          .limit(NannyLimits.photoUpdateListen)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> send(PhotoUpdateWrite write) => _guarded(
    () => _updates(write.householdId, write.shiftId).add({
      'photoId': write.photoId,
      'caption': write.caption,
      'childIds': write.childIds,
      'byMemberId': write.byMemberId,
      'createdAt': FieldValue.serverTimestamp(),
      'delivery': pendingDelivery,
    }),
  );

  @override
  Future<void> remove({
    required String householdId,
    required String shiftId,
    required String updateId,
  }) => _guarded(() => _updates(householdId, shiftId).doc(updateId).delete());

  Future<void> _guarded(Future<Object?> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
