import '../../../shared/time/calendar_date.dart';
import '../model/kid_routine.dart';
import '../model/kid_routine_tick.dart';

/// The household's kid routines (kid-routines ADR-0001).
abstract interface class KidRoutineRepository {
  /// A bound on the read (`BE-08`): three parts of a day for a dozen
  /// children, with room for weekend ones.
  static const routineLimit = 100;

  Stream<List<KidRoutine>> watchRoutines(String householdId);

  /// The routines naming [kidId] — the only ones a child's own grant reads,
  /// asked for exactly (`array-contains`), because a rule is not a filter.
  Stream<List<KidRoutine>> watchRoutinesFor({
    required String householdId,
    required String kidId,
  });

  /// What [kidId] has ticked on [date], across their routines.
  Stream<List<KidRoutineTick>> watchTicks({
    required String householdId,
    required String kidId,
    required CalendarDate date,
  });

  /// Writes the whole done list for one child's day of one routine; the id is
  /// derived, so a repeat is the same write.
  Future<void> saveTick({
    required String householdId,
    required KidRoutineTick tick,
  });

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
