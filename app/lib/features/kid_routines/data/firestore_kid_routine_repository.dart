import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/kid_routine.dart';
import 'kid_routine_repository.dart';

final class FirestoreKidRoutineRepository implements KidRoutineRepository {
  FirestoreKidRoutineRepository(this._firestore);

  static const householdsPath = 'households';
  static const routinesPath = 'kidRoutines';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(routinesPath);

  CollectionReference<KidRoutine> _routines(String householdId) =>
      typedCollection(
        _raw(householdId),
        fromJson: KidRoutine.fromJson,
        toJson: (routine) => routine.toJson(),
      );

  @override
  Stream<List<KidRoutine>> watchRoutines(String householdId) =>
      _routines(householdId)
          .limit(KidRoutineRepository.routineLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> saveRoutine({
    required String householdId,
    required KidRoutine routine,
  }) {
    if (routine.id.isNotEmpty) {
      // A change never rewrites who made it or when (the rules refuse that).
      final stored = routine.toJson()
        ..remove('createdBy')
        ..remove('createdAt');
      return _guarded(() => _raw(householdId).doc(routine.id).update(stored));
    }
    final document = _routines(householdId).doc();
    return _guarded(() => document.set(routine.copyWith(id: document.id)));
  }

  @override
  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  }) => _guarded(() => _routines(householdId).doc(routineId).delete());

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
