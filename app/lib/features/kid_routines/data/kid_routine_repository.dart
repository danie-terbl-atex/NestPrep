import '../model/kid_routine.dart';

/// The household's kid routines (kid-routines ADR-0001).
abstract interface class KidRoutineRepository {
  /// A bound on the read (`BE-08`): three parts of a day for a dozen
  /// children, with room for weekend ones.
  static const routineLimit = 100;

  Stream<List<KidRoutine>> watchRoutines(String householdId);

  /// Adds a routine (an empty id) or changes one.
  Future<void> saveRoutine({
    required String householdId,
    required KidRoutine routine,
  });

  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  });
}
