import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/shift/helper_shift.dart';
import 'helper_shift_repository.dart';

final class FirestoreHelperShiftRepository implements HelperShiftRepository {
  FirestoreHelperShiftRepository(this._firestore);

  static const householdsPath = 'households';
  static const shiftsPath = 'homeCareShifts';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _shifts(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(shiftsPath);

  static Never _readOnly(Object _) =>
      throw UnsupportedError('written field by field');

  @override
  Stream<List<HelperShift>> watchShifts(
    String householdId, {
    String? helperId,
  }) {
    final shifts = typedCollection(
      _shifts(householdId),
      fromJson: HelperShift.fromJson,
      toJson: _readOnly,
    );
    final asked = helperId == null
        ? shifts
        : shifts.where('helperId', isEqualTo: helperId);
    return asked
        .orderBy('startedAt', descending: true)
        .limit(HelperShiftRepository.shiftLimit)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
        .handleError((Object error) => throw failureFromFirebase(error));
  }

  @override
  Stream<List<HelperShift>> watchOpenShifts(
    String householdId, {
    String? helperId,
  }) {
    final open = typedCollection(
      _shifts(householdId),
      fromJson: HelperShift.fromJson,
      toJson: _readOnly,
    ).where('status', isEqualTo: HelperShift.open);
    final asked = helperId == null
        ? open
        : open.where('helperId', isEqualTo: helperId);
    return asked
        .limit(HelperShiftRepository.openShiftLimit)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
        .handleError((Object error) => throw failureFromFirebase(error));
  }

  @override
  Future<void> startShift({
    required String householdId,
    required String helperId,
    required String by,
  }) => _guarded(
    () => _shifts(householdId).doc().set({
      'helperId': helperId,
      'status': HelperShift.open,
      'startedAt': FieldValue.serverTimestamp(),
      'startedBy': by,
      'startedVia': HelperShift.app,
      'endedAt': null,
      'endedBy': null,
      'endedVia': null,
    }),
  );

  @override
  Future<void> endShift({
    required String householdId,
    required String shiftId,
    required String by,
  }) => _guarded(
    () => _shifts(householdId).doc(shiftId).update({
      'status': HelperShift.ended,
      'endedAt': FieldValue.serverTimestamp(),
      'endedBy': by,
      'endedVia': HelperShift.app,
    }),
  );

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
