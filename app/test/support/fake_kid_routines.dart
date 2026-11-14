import 'dart:async';

import 'package:nestprep/features/kid_routines/data/kid_routine_repository.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_slot.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_step.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'household_fixtures.dart';

/// The household's kid routines, driven by hand (kid-routines ADR-0001).
final class FakeKidRoutineRepository implements KidRoutineRepository {
  final _routines = StreamController<List<KidRoutine>>.broadcast();

  final saved = <KidRoutine>[];
  final deleted = <String>[];
  AppFailure? saveFailure;

  void emit(List<KidRoutine> routines) => _routines.add(routines);
  void failWith(Object error) => _routines.addError(error);
  Future<void> close() => _routines.close();

  @override
  Stream<List<KidRoutine>> watchRoutines(String householdId) =>
      _routines.stream;

  @override
  Future<void> saveRoutine({
    required String householdId,
    required KidRoutine routine,
  }) async {
    final failure = saveFailure;
    if (failure != null) throw failure;
    saved.add(routine);
  }

  @override
  Future<void> deleteRoutine({
    required String householdId,
    required String routineId,
  }) async => deleted.add(routineId);
}

abstract final class KidRoutineFixtures {
  static KidRoutine morning({
    String id = 'morning',
    String name = 'Morning',
    List<String> kidIds = const [Fixtures.kidMemberId],
    int points = 3,
    int? finishBy = 7 * 60 + 15,
  }) => KidRoutine(
    id: id,
    name: name,
    slot: KidRoutineSlot.morning,
    kidIds: kidIds,
    firstDate: CalendarDate(2026, 11, 2),
    recurrence: const RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      weekdays: [1, 2, 3, 4, 5],
    ),
    finishBy: finishBy,
    points: points,
    steps: const [
      KidRoutineStep(id: 's1', title: 'Get dressed', picture: 'get-dressed'),
      KidRoutineStep(id: 's2', title: 'Brush teeth', picture: 'brush-teeth'),
      KidRoutineStep(
        id: 's3',
        title: 'Pack school bag',
        picture: 'pack-school-bag',
        note: 'Check the diary first',
        parts: [
          KidRoutinePart(id: 'p1', text: 'Lunchbox', picture: 'pack-lunchbox'),
          KidRoutinePart(id: 'p2', text: 'Swimming kit', weekdays: [3]),
        ],
      ),
    ],
    createdBy: Fixtures.samMemberId,
  );
}
