import 'package:flutter/foundation.dart';

import '../home_care_room.dart';
import 'routine_visit.dart';

/// One room on one day: every routine of it that falls that day, and how far
/// through they are — what a helper sees as one big card on today's rooms
/// (home-care ADR-0004).
@immutable
final class RoomDay {
  const RoomDay({
    required this.roomId,
    required this.room,
    required this.visits,
  });

  final String roomId;

  /// Null when the room was removed after its routines were made.
  final HomeCareRoom? room;
  final List<RoutineVisit> visits;

  int get doneCount => visits.fold(0, (sum, visit) => sum + visit.doneCount);

  int get itemCount => visits.fold(0, (sum, visit) => sum + visit.itemCount);

  bool get isDone => visits.every((visit) => visit.isDone);

  /// From 0 to 1, for the room's progress bar.
  double get progress => itemCount == 0 ? 1 : doneCount / itemCount;

  @override
  bool operator ==(Object other) =>
      other is RoomDay &&
      other.roomId == roomId &&
      other.room == room &&
      listEquals(other.visits, visits);

  @override
  int get hashCode => Object.hash(roomId, room, Object.hashAll(visits));
}
