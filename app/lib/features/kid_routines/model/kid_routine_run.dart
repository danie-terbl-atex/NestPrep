import 'package:flutter/foundation.dart';

import '../../../shared/recurrence/recurrence_expansion.dart';
import '../../../shared/time/calendar_date.dart';
import 'kid_routine.dart';
import 'kid_routine_step.dart';
import 'kid_routine_tick.dart';

/// One child's go at one routine on one day: the routine and what they have
/// ticked so far (kid-routines ADR-0001).
///
/// Only steps the routine still has count, so a step a parent removed after
/// it was ticked neither shows nor holds the routine open.
@immutable
final class KidRoutineRun {
  KidRoutineRun({
    required this.routine,
    required this.kidId,
    required this.date,
    Iterable<String> doneStepIds = const [],
  }) : _done = {
         for (final step in routine.steps)
           if (doneStepIds.contains(step.id)) step.id,
       };

  final KidRoutine routine;
  final String kidId;
  final CalendarDate date;
  final Set<String> _done;

  List<KidRoutineStep> get steps => routine.steps;
  int get doneCount => _done.length;
  bool get isFinished => steps.isNotEmpty && _done.length == steps.length;
  bool isDone(KidRoutineStep step) => _done.contains(step.id);

  /// Where the child is: the first step not yet done, or the last when all
  /// are.
  int get currentIndex {
    final open = steps.indexWhere((step) => !_done.contains(step.id));
    return open < 0 ? steps.length - 1 : open;
  }

  /// What to take along for [step] today.
  List<KidRoutinePart> partsOf(KidRoutineStep step) => [
    for (final part in step.parts)
      if (part.fallsOn(date.weekday)) part,
  ];

  /// Whether ticking [step] is the one that finishes the routine.
  bool finishesWith(KidRoutineStep step) =>
      !isDone(step) && _done.length == steps.length - 1;

  /// The done list with [step] flipped, in the routine's order.
  List<String> doneAfterToggling(KidRoutineStep step) => [
    for (final each in steps)
      if (each.id == step.id ? !isDone(each) : isDone(each)) each.id,
  ];

  /// A child's routines for [date] in the order a day runs, each with its
  /// tick.
  static List<KidRoutineRun> forDay({
    required List<KidRoutine> routines,
    required List<KidRoutineTick> ticks,
    required String kidId,
    required CalendarDate date,
  }) {
    final done = {
      for (final tick in ticks)
        if (tick.kidId == kidId && tick.occurrenceDate == date)
          tick.routineId: tick.doneStepIds,
    };
    final runs = [
      for (final routine in routines)
        if (routine.kidIds.contains(kidId) &&
            routine.steps.isNotEmpty &&
            _fallsOn(routine, date))
          KidRoutineRun(
            routine: routine,
            kidId: kidId,
            date: date,
            doneStepIds: done[routine.id] ?? const [],
          ),
    ];
    return runs..sort((a, b) {
      final bySlot = a.routine.slot.index.compareTo(b.routine.slot.index);
      if (bySlot != 0) return bySlot;
      return a.routine.name.toLowerCase().compareTo(
        b.routine.name.toLowerCase(),
      );
    });
  }

  static bool _fallsOn(KidRoutine routine, CalendarDate date) =>
      expandOccurrences(
        firstDate: routine.firstDate,
        rule: routine.recurrence,
        windowStart: date,
        windowEnd: date,
      ).isNotEmpty;
}
