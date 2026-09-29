import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/model/job_step.dart';
import 'package:nestprep/features/home_care/model/room_kind.dart';
import 'package:nestprep/features/home_care/model/routine/room_routine.dart';
import 'package:nestprep/features/home_care/model/routine/routine_cadence.dart';
import 'package:nestprep/features/home_care/model/routine/routine_tick.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'household_fixtures.dart';

/// The Parkers' room routines (home-care ADR-0004): the kitchen every
/// weekday and the bathroom on Tuesdays for Thandi, and a monthly garage
/// sweep for somebody else in a room that has since been removed.
abstract final class RoutineFixtures {
  static const rooms = [
    HomeCareRoom(
      id: 'kitchen',
      name: 'Kitchen',
      kind: RoomKind.kitchen,
      createdBy: Fixtures.samMemberId,
    ),
    HomeCareRoom(
      id: 'bathroom',
      name: 'Bathroom',
      kind: RoomKind.bathroom,
      createdBy: Fixtures.samMemberId,
    ),
  ];

  static const kitchenItems = [
    JobStep(id: 'i1', text: 'Wipe the counters'),
    JobStep(id: 'i2', text: 'Sweep the floor'),
    JobStep(id: 'i3', text: 'Empty the bin'),
  ];

  static RoomRoutine kitchenDaily({required CalendarDate firstDate}) =>
      RoomRoutine(
        id: 'kitchen-daily',
        name: 'Kitchen, every weekday',
        roomId: 'kitchen',
        cadence: RoutineCadence.daily,
        items: kitchenItems,
        helperId: Fixtures.thandiMemberId,
        firstDate: firstDate,
        recurrence: RoutineCadence.daily.ruleFrom(firstDate),
        createdBy: Fixtures.samMemberId,
      );

  static RoomRoutine bathroomTuesdays({required CalendarDate firstDate}) =>
      RoomRoutine(
        id: 'bathroom-weekly',
        name: 'Bathroom, Tuesdays',
        roomId: 'bathroom',
        cadence: RoutineCadence.weekly,
        items: const [
          JobStep(id: 'i1', text: 'Clean the toilet'),
          JobStep(id: 'i2', text: 'Wipe the basin'),
        ],
        helperId: Fixtures.thandiMemberId,
        firstDate: firstDate,
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: [2],
        ),
        createdBy: Fixtures.samMemberId,
      );

  static RoomRoutine garageMonthly({required CalendarDate firstDate}) =>
      RoomRoutine(
        id: 'garage-monthly',
        name: 'Garage sweep',
        roomId: 'garage-gone',
        cadence: RoutineCadence.deepClean,
        items: const [JobStep(id: 'i1', text: 'Sweep out the garage')],
        helperId: 'm-gogo',
        firstDate: firstDate,
        recurrence: RoutineCadence.deepClean.ruleFrom(firstDate),
        createdBy: Fixtures.samMemberId,
      );

  /// A routine that falls every single day since the start of 2026 — for a
  /// screen test, which runs on whatever today really is.
  static RoomRoutine everyDay({
    String id = 'kitchen-every-day',
    String name = 'Kitchen, every day',
    String roomId = 'kitchen',
    String helperId = Fixtures.thandiMemberId,
    List<JobStep> items = kitchenItems,
  }) => RoomRoutine(
    id: id,
    name: name,
    roomId: roomId,
    cadence: RoutineCadence.daily,
    items: items,
    helperId: helperId,
    firstDate: CalendarDate(2026, 1, 1),
    recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
    createdBy: Fixtures.samMemberId,
  );

  static RoutineTick tick(
    RoomRoutine routine,
    CalendarDate day,
    List<String> done,
  ) => RoutineTick(
    id: RoutineTick.idFor(routine.id, day),
    routineId: routine.id,
    occurrenceDate: day,
    helperId: routine.helperId,
    doneItemIds: done,
    updatedBy: routine.helperId,
  );
}
