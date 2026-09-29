import 'package:flutter/foundation.dart';

import '../../../../shared/time/calendar_date.dart';
import 'room_routine.dart';

/// One routine on one day it falls on, with what has been ticked — the unit
/// both today's rooms and the parent's overview are made of (home-care
/// ADR-0004).
@immutable
final class RoutineVisit {
  const RoutineVisit({
    required this.routine,
    required this.day,
    required this.doneItemIds,
  });

  final RoomRoutine routine;
  final CalendarDate day;
  final List<String> doneItemIds;

  bool isItemDone(String itemId) => doneItemIds.contains(itemId);

  /// Only ticks for items the routine still has — an item a parent removed
  /// no longer counts.
  int get doneCount =>
      routine.items.where((item) => isItemDone(item.id)).length;

  int get itemCount => routine.items.length;

  bool get isDone => itemCount > 0 && doneCount == itemCount;

  /// The done list after [itemId] is ticked or unticked, keeping only items
  /// the routine still has.
  List<String> toggled(String itemId) => [
    for (final item in routine.items)
      if (item.id == itemId ? !isItemDone(itemId) : isItemDone(item.id))
        item.id,
  ];

  @override
  bool operator ==(Object other) =>
      other is RoutineVisit &&
      other.routine == routine &&
      other.day == day &&
      listEquals(other.doneItemIds, doneItemIds);

  @override
  int get hashCode => Object.hash(routine, day, Object.hashAll(doneItemIds));
}
