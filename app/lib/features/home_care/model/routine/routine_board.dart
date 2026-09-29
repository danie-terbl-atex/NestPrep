import '../../../../shared/time/calendar_date.dart';
import '../../../household/model/member.dart';
import '../home_care_room.dart';
import 'room_day.dart';
import 'room_routine.dart';
import 'routine_tick.dart';
import 'routine_visit.dart';

/// The room routines, this week's ticks, and the rooms and members they name,
/// as one value the routine screens render (home-care ADR-0004).
final class RoutineBoard {
  RoutineBoard({
    required this.routines,
    required this.ticks,
    required this.rooms,
    required this.members,
    required this.today,
  });

  final List<RoomRoutine> routines;
  final List<RoutineTick> ticks;
  final List<HomeCareRoom> rooms;
  final List<Member> members;

  /// Today in the household's zone (`ENG-21`).
  final CalendarDate today;

  late final Map<String, RoutineTick> _ticksById = {
    for (final tick in ticks) tick.id: tick,
  };
  late final Map<String, HomeCareRoom> _roomsById = {
    for (final room in rooms) room.id: room,
  };

  HomeCareRoom? roomById(String roomId) => _roomsById[roomId];

  Member? memberById(String memberId) =>
      members.where((member) => member.id == memberId).firstOrNull;

  RoomRoutine? routineById(String routineId) =>
      routines.where((routine) => routine.id == routineId).firstOrNull;

  /// [routine] on [day] with what is ticked, or null when it does not fall
  /// that day.
  RoutineVisit? visitOf(RoomRoutine routine, CalendarDate day) {
    if (!routine.fallsOn(day)) return null;
    final tick = _ticksById[RoutineTick.idFor(routine.id, day)];
    return RoutineVisit(
      routine: routine,
      day: day,
      doneItemIds: tick?.doneItemIds ?? const [],
    );
  }

  /// Every room with a routine on [day] — only [helperId]'s when given —
  /// rooms by name, and within a room the routines by name.
  List<RoomDay> roomsOn(CalendarDate day, {String? helperId}) {
    final byRoom = <String, List<RoutineVisit>>{};
    for (final routine in _sorted(routines)) {
      if (helperId != null && routine.helperId != helperId) continue;
      final visit = visitOf(routine, day);
      if (visit == null) continue;
      byRoom.putIfAbsent(routine.roomId, () => []).add(visit);
    }
    return _byRoomName([
      for (final MapEntry(key: roomId, value: visits) in byRoom.entries)
        RoomDay(roomId: roomId, room: roomById(roomId), visits: visits),
    ]);
  }

  /// Every routine, grouped by the room it is for, rooms by name.
  List<(HomeCareRoom?, String, List<RoomRoutine>)> get routinesByRoom {
    final byRoom = <String, List<RoomRoutine>>{};
    for (final routine in _sorted(routines)) {
      byRoom.putIfAbsent(routine.roomId, () => []).add(routine);
    }
    final grouped = [
      for (final MapEntry(key: roomId, value: list) in byRoom.entries)
        (roomById(roomId), roomId, list),
    ];
    grouped.sort((a, b) => _nameOf(a.$1).compareTo(_nameOf(b.$1)));
    return grouped;
  }

  /// How much of [day]'s routines is ticked, as items done of items due —
  /// everybody's, or [helperId]'s.
  ({int done, int due}) progressOn(CalendarDate day, {String? helperId}) {
    var done = 0;
    var due = 0;
    for (final room in roomsOn(day, helperId: helperId)) {
      done += room.doneCount;
      due += room.itemCount;
    }
    return (done: done, due: due);
  }

  /// The seven days of this week, Monday first.
  List<CalendarDate> get week => [
    for (var offset = 0; offset < 7; offset++) today.weekStart.addDays(offset),
  ];

  static List<RoomRoutine> _sorted(List<RoomRoutine> routines) =>
      [...routines]..sort((a, b) => a.name.compareTo(b.name));

  static List<RoomDay> _byRoomName(List<RoomDay> days) =>
      days..sort((a, b) => _nameOf(a.room).compareTo(_nameOf(b.room)));

  // A removed room sorts last, whatever its routines are called.
  static String _nameOf(HomeCareRoom? room) => room?.name ?? '\u{10FFFF}';
}
