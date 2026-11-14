import 'package:flutter/foundation.dart';

import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import 'kid_routine.dart';
import 'kid_routine_slot.dart';
import 'kid_routine_starter.dart';
import 'kid_routine_step.dart';

/// What is missing before a kid routine can be saved — each one a field the
/// form points at, and each one something the rules would refuse too.
enum KidRoutineDraftProblem { noName, noKids, noDays, noSteps }

/// A kid routine as a parent writes it (kid-routines ADR-0001). The days are
/// the weekdays it runs on; it is saved as a weekly rule on exactly those.
@immutable
final class KidRoutineDraft {
  const KidRoutineDraft({
    required this.slot,
    required this.firstDate,
    this.id,
    this.name = '',
    this.kidIds = const {},
    this.weekdays = schoolDays,
    this.finishBy,
    this.points = 0,
    this.steps = const [],
  });

  /// A new routine for [slot], already holding that slot's starter steps.
  factory KidRoutineDraft.starting({
    required KidRoutineSlot slot,
    required CalendarDate today,
    required String name,
    required List<KidRoutineStarter> starters,
    Set<String> kidIds = const {},
  }) => KidRoutineDraft(
    slot: slot,
    firstDate: today,
    name: name,
    kidIds: kidIds,
    steps: [
      for (final (index, starter) in starters.indexed)
        KidRoutineStep(
          id: 's${index + 1}',
          title: starter.title,
          picture: starter.picture,
        ),
    ],
  );

  factory KidRoutineDraft.of(KidRoutine routine) => KidRoutineDraft(
    id: routine.id,
    slot: routine.slot,
    firstDate: routine.firstDate,
    name: routine.name,
    kidIds: routine.kidIds.toSet(),
    weekdays: _weekdaysOf(routine),
    finishBy: routine.finishBy,
    points: routine.points,
    steps: routine.steps,
  );

  static const schoolDays = {1, 2, 3, 4, 5};
  static const weekend = {6, 7};
  static const everyDay = {1, 2, 3, 4, 5, 6, 7};

  /// A weekly rule with no weekdays lands on its first date's weekday; a
  /// daily one on every day; no rule is the one day it starts.
  static Set<int> _weekdaysOf(KidRoutine routine) {
    final rule = routine.recurrence;
    if (rule == null) return {routine.firstDate.weekday};
    if (rule.frequency == RecurrenceFrequency.daily) return everyDay;
    return rule.weekdays.isEmpty
        ? {routine.firstDate.weekday}
        : rule.weekdays.toSet();
  }

  /// Null for a routine not yet saved.
  final String? id;
  final KidRoutineSlot slot;
  final CalendarDate firstDate;
  final String name;
  final Set<String> kidIds;
  final Set<int> weekdays;
  final int? finishBy;
  final int points;
  final List<KidRoutineStep> steps;

  String get cleanName => name.trim();

  List<KidRoutineDraftProblem> get problems => [
    if (cleanName.isEmpty) KidRoutineDraftProblem.noName,
    if (kidIds.isEmpty) KidRoutineDraftProblem.noKids,
    if (weekdays.isEmpty) KidRoutineDraftProblem.noDays,
    if (steps.isEmpty) KidRoutineDraftProblem.noSteps,
  ];

  bool get isComplete => problems.isEmpty;

  bool get canAddStep => steps.length < KidRoutine.stepLimit;

  /// The same routine as a new one, for a child who needs it a little
  /// different.
  KidRoutineDraft asCopy({required String name, required CalendarDate today}) =>
      KidRoutineDraft(
        slot: slot,
        firstDate: today,
        name: name,
        weekdays: weekdays,
        finishBy: finishBy,
        points: points,
        steps: steps,
      );

  KidRoutineDraft withName(String next) => _copy(name: next);

  KidRoutineDraft withSlot(KidRoutineSlot next) => _copy(slot: next);

  KidRoutineDraft withKidToggled(String kidId) => _copy(
    kidIds: kidIds.contains(kidId)
        ? ({...kidIds}..remove(kidId))
        : {...kidIds, kidId},
  );

  KidRoutineDraft withWeekdays(Set<int> next) => _copy(weekdays: next);

  KidRoutineDraft withWeekdayToggled(int weekday) => _copy(
    weekdays: weekdays.contains(weekday)
        ? ({...weekdays}..remove(weekday))
        : {...weekdays, weekday},
  );

  KidRoutineDraft withFinishBy(int? minutes) => _copy(finishBy: () => minutes);

  KidRoutineDraft withPoints(int next) => _copy(points: next);

  /// A step id no other step here has.
  String get nextStepId {
    final used = steps.map((step) => step.id).toSet();
    var next = steps.length + 1;
    while (used.contains('s$next')) {
      next++;
    }
    return 's$next';
  }

  /// Adds [step], or replaces the step with its id.
  KidRoutineDraft withStep(KidRoutineStep step) {
    final exists = steps.any((candidate) => candidate.id == step.id);
    if (!exists && !canAddStep) return this;
    return _copy(
      steps: exists
          ? [
              for (final candidate in steps)
                candidate.id == step.id ? step : candidate,
            ]
          : [...steps, step],
    );
  }

  KidRoutineDraft withoutStep(String stepId) => _copy(
    steps: [
      for (final step in steps)
        if (step.id != stepId) step,
    ],
  );

  /// Moves the step at [from] to sit at [to] in the list without it.
  KidRoutineDraft withStepMoved(int from, int to) {
    if (from < 0 || from >= steps.length) return this;
    final next = [...steps];
    final step = next.removeAt(from);
    next.insert(to.clamp(0, next.length), step);
    return _copy(steps: next);
  }

  /// The routine this draft saves as, stamped with [createdBy] when new.
  KidRoutine toRoutine({required String createdBy}) => KidRoutine(
    id: id ?? '',
    name: cleanName,
    slot: slot,
    kidIds: kidIds.toList()..sort(),
    firstDate: firstDate,
    recurrence: RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      weekdays: weekdays.toList()..sort(),
    ),
    finishBy: finishBy,
    points: points,
    steps: steps,
    createdBy: createdBy,
  );

  KidRoutineDraft _copy({
    String? name,
    KidRoutineSlot? slot,
    Set<String>? kidIds,
    Set<int>? weekdays,
    int? Function()? finishBy,
    int? points,
    List<KidRoutineStep>? steps,
  }) => KidRoutineDraft(
    id: id,
    slot: slot ?? this.slot,
    firstDate: firstDate,
    name: name ?? this.name,
    kidIds: kidIds ?? this.kidIds,
    weekdays: weekdays ?? this.weekdays,
    finishBy: finishBy == null ? this.finishBy : finishBy(),
    points: points ?? this.points,
    steps: steps ?? this.steps,
  );
}
