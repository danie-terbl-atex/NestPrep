import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'pickup_change.dart';
import 'pickup_person.dart';
import 'pickup_plan.dart';
import 'school_run.dart';

/// Who may collect the children and the school-run week, as the listeners last
/// saw them (nanny-hub ADR-0005). The one value the pickup screens render;
/// nothing here is kept that a listener does not also carry.
@immutable
final class NannyPickups {
  NannyPickups({
    required List<PickupPerson> people,
    required List<SchoolRun> runs,
    required List<PickupChange> changes,
  }) : people = List.unmodifiable(
         <PickupPerson>[...people]..sort((a, b) => a.name.compareTo(b.name)),
       ),
       _runs = Map.unmodifiable({for (final run in runs) run.id: run}),
       _changes = Map.unmodifiable({
         for (final change in changes) change.id: change,
       }),
       changes = List.unmodifiable(
         <PickupChange>[...changes]..sort((a, b) => a.date.compareTo(b.date)),
       );

  static final empty = NannyPickups(people: [], runs: [], changes: []);

  /// By name.
  final List<PickupPerson> people;
  final Map<String, SchoolRun> _runs;
  final Map<String, PickupChange> _changes;

  /// Every change, soonest first.
  final List<PickupChange> changes;

  PickupPerson? personById(String? personId) =>
      people.where((person) => person.id == personId).firstOrNull;

  /// Everybody a parent said may collect [childId], by name. Empty means the
  /// child goes to nobody.
  List<PickupPerson> allowedFor(String childId) => [
    for (final person in people)
      if (person.mayCollect(childId)) person,
  ];

  SchoolRun? runFor(String childId, int weekday) =>
      _runs[SchoolRun.idFor(childId, weekday)];

  /// The changes for [childId] from [today] on.
  List<PickupChange> upcomingFor(String childId, CalendarDate today) => [
    for (final change in changes)
      if (change.childId == childId && !change.date.isBefore(today)) change,
  ];

  /// Who collects [childId] on [date]: that date's change if a parent made
  /// one, otherwise the weekday's usual run, otherwise null — no school run.
  PickupPlan? planFor(String childId, CalendarDate date) {
    final change = _changes[PickupChange.idFor(childId, date)];
    if (change != null) {
      return PickupPlan(
        collector: change.collector,
        isChange: true,
        atMinute: change.atMinute,
        note: change.note,
      );
    }
    final run = runFor(childId, date.weekday);
    if (run == null) return null;
    return PickupPlan(
      collector: run.collector,
      isChange: false,
      atMinute: run.atMinute,
      place: run.place,
    );
  }
}
