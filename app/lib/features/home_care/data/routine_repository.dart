import '../../../shared/time/calendar_date.dart';
import '../model/routine/room_routine.dart';
import '../model/routine/routine_tick.dart';

/// The household's room routines and the days ticked (home-care ADR-0004).
abstract interface class RoutineRepository {
  /// Bounds on the reads (`BE-08`): more routines than a house has rooms
  /// times cadences, and a week of ticks for every one of them.
  static const routineLimit = 120;
  static const tickLimit = 900;

  /// Every routine, or — for a helper holding `own` — only [helperId]'s,
  /// which is what the rules let her ask for (household ADR-0003).
  Stream<List<RoomRoutine>> watchRoutines(
    String householdId, {
    String? helperId,
  });

  /// The ticks for days from [from] to [to] inclusive, scoped the same way.
  Stream<List<RoutineTick>> watchTicks(
    String householdId, {
    required CalendarDate from,
    required CalendarDate to,
    String? helperId,
  });

  /// Adds a routine (an empty id) or changes one.
  Future<void> saveRoutine({
    required String householdId,
    required RoomRoutine routine,
  });

  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  });

  /// Writes what is done on [day] of [routine]. The same day written twice
  /// is the same document (`BE-06`).
  Future<void> setDoneItems({
    required String householdId,
    required RoomRoutine routine,
    required CalendarDate day,
    required List<String> doneItemIds,
    required String by,
  });
}
