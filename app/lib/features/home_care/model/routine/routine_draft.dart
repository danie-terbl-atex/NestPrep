import 'package:flutter/foundation.dart';

import '../../../../shared/recurrence/recurrence_rule.dart';
import '../../../../shared/time/calendar_date.dart';
import '../job_step.dart';
import 'room_routine.dart';
import 'routine_cadence.dart';

/// What is missing before a routine can be saved — each one a field the form
/// points at, and each one something the rules would refuse too.
enum RoutineDraftProblem { noName, noRoom, noHelper, noItems }

/// A room routine as a parent writes it (home-care ADR-0004): the sheet that
/// adds one and the sheet that changes one both fill this.
@immutable
final class RoutineDraft {
  const RoutineDraft({
    required this.firstDate,
    required this.recurrence,
    this.id,
    this.name = '',
    this.roomId,
    this.helperId,
    this.cadence = RoutineCadence.daily,
    this.items = const [],
  });

  /// A new routine starting [today], on the daily cadence's rule.
  factory RoutineDraft.startingOn(CalendarDate today) => RoutineDraft(
    firstDate: today,
    recurrence: RoutineCadence.daily.ruleFrom(today),
  );

  factory RoutineDraft.of(RoomRoutine routine) => RoutineDraft(
    id: routine.id,
    name: routine.name,
    roomId: routine.roomId,
    helperId: routine.helperId,
    cadence: routine.cadence,
    firstDate: routine.firstDate,
    recurrence: routine.recurrence,
    items: routine.items,
  );

  /// Null for a routine not yet saved.
  final String? id;
  final String name;
  final String? roomId;
  final String? helperId;
  final RoutineCadence cadence;
  final CalendarDate firstDate;

  /// Null for a one-off.
  final RecurrenceRule? recurrence;
  final List<JobStep> items;

  String get cleanName => name.trim();

  List<RoutineDraftProblem> get problems => [
    if (cleanName.isEmpty) RoutineDraftProblem.noName,
    if (roomId == null) RoutineDraftProblem.noRoom,
    if (helperId == null) RoutineDraftProblem.noHelper,
    if (items.isEmpty) RoutineDraftProblem.noItems,
  ];

  bool get isComplete => problems.isEmpty;

  bool get canAddItem => items.length < RoomRoutine.itemLimit;

  /// A different cadence starts from that cadence's rule — somebody switching
  /// "daily" to "deep clean" means the deep clean's rhythm, not Monday to
  /// Friday again.
  RoutineDraft withCadence(RoutineCadence next) =>
      _copy(cadence: next, recurrence: () => next.ruleFrom(firstDate));

  RoutineDraft withRecurrence(RecurrenceRule? rule) =>
      _copy(recurrence: () => rule);

  RoutineDraft withName(String next) => _copy(name: next);

  RoutineDraft withRoom(String next) => _copy(roomId: next);

  RoutineDraft withHelper(String next) => _copy(helperId: next);

  RoutineDraft withFirstDate(CalendarDate next) => _copy(firstDate: next);

  /// A new item at the end, with an id no other item here has.
  RoutineDraft withItemAdded(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !canAddItem) return this;
    final used = items.map((item) => item.id).toSet();
    var next = items.length + 1;
    while (used.contains('i$next')) {
      next++;
    }
    return _copy(
      items: [
        ...items,
        JobStep(id: 'i$next', text: trimmed),
      ],
    );
  }

  RoutineDraft withoutItem(String itemId) => _copy(
    items: [
      for (final item in items)
        if (item.id != itemId) item,
    ],
  );

  /// The routine this draft saves as, stamped with [createdBy] when new.
  RoomRoutine toRoutine({required String createdBy}) => RoomRoutine(
    id: id ?? '',
    name: cleanName,
    roomId: roomId ?? '',
    cadence: cadence,
    items: items,
    helperId: helperId ?? '',
    firstDate: firstDate,
    recurrence: recurrence,
    createdBy: createdBy,
  );

  RoutineDraft _copy({
    String? name,
    String? roomId,
    String? helperId,
    RoutineCadence? cadence,
    CalendarDate? firstDate,
    RecurrenceRule? Function()? recurrence,
    List<JobStep>? items,
  }) => RoutineDraft(
    id: id,
    name: name ?? this.name,
    roomId: roomId ?? this.roomId,
    helperId: helperId ?? this.helperId,
    cadence: cadence ?? this.cadence,
    firstDate: firstDate ?? this.firstDate,
    recurrence: recurrence == null ? this.recurrence : recurrence(),
    items: items ?? this.items,
  );
}
