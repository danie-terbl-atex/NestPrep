import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/kid_routine.dart';
import '../model/kid_routine_tick.dart';
import 'kid_routine_repository.dart';

final class FirestoreKidRoutineRepository implements KidRoutineRepository {
  FirestoreKidRoutineRepository(this._firestore);

  static const householdsPath = 'households';
  static const routinesPath = 'kidRoutines';
  static const ticksPath = 'kidRoutineTicks';

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

  CollectionReference<KidRoutineTick> _ticks(String householdId) =>
      typedCollection(
        _firestore
            .collection(householdsPath)
            .doc(householdId)
            .collection(ticksPath),
        fromJson: KidRoutineTick.fromJson,
        toJson: (tick) => tick.toJson(),
      );

  @override
  Stream<List<KidRoutine>> watchRoutinesFor({
    required String householdId,
    required String kidId,
  }) =>
      _routines(householdId)
          .where('kidIds', arrayContains: kidId)
          .limit(KidRoutineRepository.routineLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<KidRoutineTick>> watchTicks({
    required String householdId,
    required String kidId,
    required CalendarDate date,
  }) =>
      _ticks(householdId)
          .where('kidId', isEqualTo: kidId)
          .where('occurrenceDate', isEqualTo: date.iso)
          .limit(KidRoutineRepository.routineLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> saveTick({
    required String householdId,
    required KidRoutineTick tick,
  }) => _guarded(
    () => _ticks(householdId).doc(tick.id).set(tick.copyWith(updatedAt: null)),
  );

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
