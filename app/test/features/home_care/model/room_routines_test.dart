import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/model/job_step.dart';
import 'package:nestprep/features/home_care/model/room_kind.dart';
import 'package:nestprep/features/home_care/model/routine/room_routine.dart';
import 'package:nestprep/features/home_care/model/routine/routine_board.dart';
import 'package:nestprep/features/home_care/model/routine/routine_cadence.dart';
import 'package:nestprep/features/home_care/model/routine/routine_draft.dart';
import 'package:nestprep/features/home_care/model/routine/routine_tick.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/home_care_routine_fixtures.dart';

/// Room routines (home-care ADR-0004): a cadence presets the shared rule,
/// the shared expansion decides the days, and a day's ticks are read by id.
void main() {
  // A Tuesday.
  final tuesday = CalendarDate(2026, 9, 29);
  final saturday = CalendarDate(2026, 10, 3);

  group('a cadence starts with the rule a household means by it', () {
    test('daily is a helper’s working week, Monday to Friday', () {
      final rule = RoutineCadence.daily.ruleFrom(tuesday);
      expect(rule.frequency, RecurrenceFrequency.weekly);
      expect(rule.weekdays, [1, 2, 3, 4, 5]);
    });

    test('weekly is the first day’s weekday', () {
      expect(RoutineCadence.weekly.ruleFrom(saturday).weekdays, [6]);
    });

    test('a deep clean comes round monthly', () {
      expect(
        RoutineCadence.deepClean.ruleFrom(tuesday).frequency,
        RecurrenceFrequency.monthly,
      );
    });
  });

  group('the days a routine falls on', () {
    test('a daily routine falls on weekdays and not at the weekend', () {
      final routine = RoutineFixtures.kitchenDaily(firstDate: tuesday);
      expect(routine.fallsOn(tuesday), isTrue);
      expect(routine.fallsOn(CalendarDate(2026, 10, 2)), isTrue);
      expect(routine.fallsOn(saturday), isFalse);
    });

    test('nothing falls before the routine starts', () {
      final routine = RoutineFixtures.kitchenDaily(firstDate: tuesday);
      expect(routine.fallsOn(CalendarDate(2026, 9, 28)), isFalse);
    });

    test('a one-off falls on its own day only', () {
      final routine = RoutineFixtures.kitchenDaily(
        firstDate: tuesday,
      ).copyWith(recurrence: null);
      expect(routine.fallsOn(tuesday), isTrue);
      expect(routine.fallsOn(tuesday.addDays(1)), isFalse);
    });
  });

  group('the board', () {
    RoutineBoard board({
      List<RoomRoutine>? routines,
      List<RoutineTick> ticks = const [],
    }) => RoutineBoard(
      routines:
          routines ??
          [
            RoutineFixtures.kitchenDaily(firstDate: tuesday),
            RoutineFixtures.bathroomTuesdays(firstDate: tuesday),
            RoutineFixtures.garageMonthly(firstDate: tuesday),
          ],
      ticks: ticks,
      rooms: RoutineFixtures.rooms,
      members: const [],
      today: tuesday,
    );

    test('groups today’s routines by room, rooms by name', () {
      final days = board().roomsOn(tuesday);
      expect(days.map((day) => day.room?.name), ['Bathroom', 'Kitchen', null]);
      expect(days.last.roomId, 'garage-gone');
    });

    test('asks only for a helper’s own when told whose', () {
      final days = board().roomsOn(tuesday, helperId: 'm-thandi');
      expect(days.map((day) => day.roomId), ['bathroom', 'kitchen']);
    });

    test('leaves out a room with nothing on that day', () {
      final days = board().roomsOn(tuesday.addDays(1));
      expect(days.map((day) => day.roomId), ['kitchen']);
    });

    test('reads a day’s ticks by the routine and the day', () {
      final kitchen = RoutineFixtures.kitchenDaily(firstDate: tuesday);
      final ticked = board(
        routines: [kitchen],
        ticks: [
          RoutineFixtures.tick(kitchen, tuesday, ['i1', 'i2']),
        ],
      );
      final visit = ticked.visitOf(kitchen, tuesday)!;
      expect(visit.doneCount, 2);
      expect(visit.isDone, isFalse);
      // Yesterday's ticks are not today's.
      expect(ticked.visitOf(kitchen, tuesday.addDays(1))!.doneCount, 0);
      expect(ticked.visitOf(kitchen, saturday), isNull);
    });

    test('a room is done when every item of every routine in it is', () {
      final kitchen = RoutineFixtures.kitchenDaily(firstDate: tuesday);
      final all = kitchen.items.map((item) => item.id).toList();
      final day = board(
        routines: [kitchen],
        ticks: [RoutineFixtures.tick(kitchen, tuesday, all)],
      ).roomsOn(tuesday).single;
      expect(day.isDone, isTrue);
      expect(day.progress, 1);
    });

    test('lists every routine under its room, the removed room last', () {
      final grouped = board().routinesByRoom;
      expect(grouped.map((group) => group.$2), [
        'bathroom',
        'kitchen',
        'garage-gone',
      ]);
    });

    test('knows the seven days of this week, Monday first', () {
      final week = board().week;
      expect(week.first, CalendarDate(2026, 9, 28));
      expect(week.last, CalendarDate(2026, 10, 4));
    });
  });

  group('ticking an item', () {
    test('adds it, keeps the others, and drops ticks for removed items', () {
      final kitchen = RoutineFixtures.kitchenDaily(firstDate: tuesday);
      final visit = RoutineBoard(
        routines: [kitchen],
        ticks: [
          RoutineFixtures.tick(kitchen, tuesday, ['i1', 'gone']),
        ],
        rooms: const [],
        members: const [],
        today: tuesday,
      ).visitOf(kitchen, tuesday)!;
      expect(visit.doneCount, 1, reason: 'a removed item does not count');
      expect(visit.toggled('i3'), ['i1', 'i3']);
      expect(visit.toggled('i1'), isEmpty);
    });
  });

  group('a draft', () {
    test('says everything that is missing', () {
      expect(RoutineDraft.startingOn(tuesday).problems, [
        RoutineDraftProblem.noName,
        RoutineDraftProblem.noRoom,
        RoutineDraftProblem.noHelper,
        RoutineDraftProblem.noItems,
      ]);
    });

    test('a cadence changed starts again from that cadence’s rule', () {
      final draft = RoutineDraft.startingOn(
        tuesday,
      ).withCadence(RoutineCadence.deepClean);
      expect(draft.recurrence?.frequency, RecurrenceFrequency.monthly);
      expect(draft.withRecurrence(null).recurrence, isNull);
    });

    test('gives each new item an id no other item has', () {
      final draft = RoutineDraft.startingOn(tuesday)
          .withItemAdded('Wipe')
          .withItemAdded('Sweep')
          .withoutItem('i1')
          .withItemAdded('Mop')
          .withItemAdded('   ');
      expect(draft.items.map((item) => item.id), ['i2', 'i3']);
      expect(draft.items.map((item) => item.text), ['Sweep', 'Mop']);
    });

    test('stops adding at the rules’ limit', () {
      var draft = RoutineDraft.startingOn(tuesday);
      for (var n = 0; n < RoomRoutine.itemLimit + 3; n++) {
        draft = draft.withItemAdded('Item $n');
      }
      expect(draft.items, hasLength(RoomRoutine.itemLimit));
      expect(draft.canAddItem, isFalse);
    });

    test('saves trimmed, with who made it, and keeps its id when changed', () {
      final routine = RoutineDraft.startingOn(tuesday)
          .withName('  Kitchen  ')
          .withRoom('kitchen')
          .withHelper('m-thandi')
          .withItemAdded('Wipe')
          .toRoutine(createdBy: 'm-sam');
      expect(routine.name, 'Kitchen');
      expect(routine.id, isEmpty);
      expect(routine.createdBy, 'm-sam');
      final again = RoutineDraft.of(routine.copyWith(id: 'r1'));
      expect(again.toRoutine(createdBy: 'm-sam').id, 'r1');
      expect(again.isComplete, isTrue);
    });
  });

  test('the room and step fixtures are what the tests above assume', () {
    expect(RoutineFixtures.rooms, contains(isA<HomeCareRoom>()));
    expect(
      RoutineFixtures.kitchenDaily(firstDate: tuesday).items,
      everyElement(isA<JobStep>()),
    );
    expect(RoomKind.values, contains(RoomKind.kitchen));
  });
}
