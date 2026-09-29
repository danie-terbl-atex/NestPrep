import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/routine/room_routine.dart';
import '../model/routine/routine_tick.dart';
import 'routine_repository.dart';

final class FirestoreRoutineRepository implements RoutineRepository {
  FirestoreRoutineRepository(this._firestore);

  static const householdsPath = 'households';
  static const routinesPath = 'homeCareRoutines';
  static const ticksPath = 'homeCareRoutineTicks';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(
    String householdId,
    String path,
  ) => _firestore.collection(householdsPath).doc(householdId).collection(path);

  CollectionReference<RoomRoutine> _routines(String householdId) =>
      typedCollection(
        _raw(householdId, routinesPath),
        fromJson: RoomRoutine.fromJson,
        toJson: (routine) => routine.toJson(),
      );

  CollectionReference<RoutineTick> _ticks(String householdId) =>
      typedCollection(
        _raw(householdId, ticksPath),
        fromJson: RoutineTick.fromJson,
        toJson: (tick) => tick.toJson(),
      );

  @override
  Stream<List<RoomRoutine>> watchRoutines(
    String householdId, {
    String? helperId,
  }) =>
      (helperId == null
              ? _routines(householdId)
              : _routines(householdId).where('helperId', isEqualTo: helperId))
          .limit(RoutineRepository.routineLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<RoutineTick>> watchTicks(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
    String? helperId,
  }) =>
      (helperId == null
              ? _ticks(householdId)
              : _ticks(householdId).where('helperId', isEqualTo: helperId))
          // A range on the date string, which sorts as the calendar does
          // because the format is YYYY-MM-DD (`ENG-21`, todos ADR-0002).
          .where('occurrenceDate', isGreaterThanOrEqualTo: from.iso)
          .where('occurrenceDate', isLessThanOrEqualTo: to.iso)
          .limit(RoutineRepository.tickLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> saveRoutine({
    required String householdId,
    required RoomRoutine routine,
  }) {
    if (routine.id.isNotEmpty) {
      // A change never rewrites who made it or when (the rules refuse that).
      final stored = routine.toJson()
        ..remove('createdBy')
        ..remove('createdAt');
      return _guarded(
        () => _raw(householdId, routinesPath).doc(routine.id).update(stored),
      );
    }
    final document = _routines(householdId).doc();
    return _guarded(() => document.set(routine.copyWith(id: document.id)));
  }

  @override
  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  }) => _guarded(() => _routines(householdId).doc(routineId).delete());

  @override
  Future<void> setDoneItems({
    required String householdId,
    required RoomRoutine routine,
    required CalendarDate day,
    required List<String> doneItemIds,
    required String by,
  }) {
    final id = RoutineTick.idFor(routine.id, day);
    return _guarded(
      () => _ticks(householdId)
          .doc(id)
          .set(
            RoutineTick(
              id: id,
              routineId: routine.id,
              occurrenceDate: day,
              helperId: routine.helperId,
              doneItemIds: doneItemIds,
              updatedBy: by,
            ),
          ),
    );
  }

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
