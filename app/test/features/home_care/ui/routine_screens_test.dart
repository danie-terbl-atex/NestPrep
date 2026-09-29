import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/model/job_step.dart';
import 'package:nestprep/features/home_care/model/routine/room_routine.dart';
import 'package:nestprep/features/home_care/model/routine/routine_cadence.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/home_care_routine_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// The room routines through the real routes (home-care ADR-0004): a
/// parent's overview and sheet, a helper's rooms for today, and all four
/// states of each.
void main() {
  late HomeCareHarness harness;
  final routinesPath = HomeCareRoute.routinesPathFor(Fixtures.householdId);
  final todayPath = HomeCareRoute.todayPathFor(Fixtures.householdId);

  setUp(() => harness = HomeCareHarness());

  Future<void> feedHome(
    WidgetTester tester, {
    List<HomeCareRoom> rooms = RoutineFixtures.rooms,
  }) => harness.feedShell(tester, rooms: rooms);

  tearDown(() => harness.close());

  Future<void> open(
    WidgetTester tester,
    String location, {
    bool asHelper = false,
  }) async {
    HomeCareHarness.makeRoom(tester);
    await harness.pump(
      tester,
      location: location,
      view: asHelper ? HomeCareFixtures.helperView() : null,
    );
    await feedHome(tester);
  }

  group('the parent’s overview', () {
    testWidgets('holds its layout while it loads', (tester) async {
      HomeCareHarness.makeRoom(tester);
      await harness.pump(tester, location: routinesPath);
      await tester.pump();
      expect(find.text(HomeCareRoutineCopy.routines), findsOneWidget);
      expect(find.text('Kitchen, every day'), findsNothing);
    });

    testWidgets('shows today per room, and every routine by room', (
      tester,
    ) async {
      await open(tester, routinesPath);
      await harness.emitRoutines(
        tester,
        routineList: [
          RoutineFixtures.everyDay(),
          RoutineFixtures.everyDay(
            id: 'bath',
            name: 'Bathroom, every day',
            roomId: 'bathroom',
            items: const [JobStep(id: 'i1', text: 'Wipe the basin')],
          ),
        ],
      );
      expect(find.text(HomeCareRoutineCopy.todayHeading), findsOneWidget);
      expect(
        find.text(
          HomeCareRoutineCopy.routineAndWho(
            'Kitchen, every day',
            'Thandi Helper',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(HomeCareRoutineCopy.done(0, 3)), findsOneWidget);
      expect(find.text('Bathroom, every day'), findsOneWidget);
      expect(find.text(HomeCareRoutineCopy.newRoutine), findsOneWidget);
    });

    testWidgets('a household with no rooms is sent to add them first', (
      tester,
    ) async {
      HomeCareHarness.makeRoom(tester);
      await harness.pump(tester, location: routinesPath);
      await feedHome(tester, rooms: const []);
      await harness.emitRoutines(tester, routineList: const []);
      expect(find.text(HomeCareRoutineCopy.noRoomsTitle), findsOneWidget);
      await tester.tap(find.text(HomeCareRoutineCopy.addRooms));
      await tester.pumpAndSettle();
      expect(find.text(HomeCareLibraryCopy.rooms), findsWidgets);
    });

    testWidgets('no routine yet says what one is, with the way to the first', (
      tester,
    ) async {
      await open(tester, routinesPath);
      await harness.emitRoutines(tester, routineList: const []);
      expect(find.text(HomeCareRoutineCopy.emptyTitle), findsOneWidget);
      expect(find.text(HomeCareRoutineCopy.newRoutine), findsWidgets);
    });

    testWidgets('says what went wrong in words, with a retry', (tester) async {
      await open(tester, routinesPath);
      harness.routines.failRoutinesWith(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const UnavailableFailure())),
        findsOneWidget,
      );
      await tester.tap(find.text(AppCopy.retry));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      expect(harness.routines.routinesAskedFor, hasLength(2));
    });

    testWidgets('a new routine: room, helper, cadence and items, saved', (
      tester,
    ) async {
      await open(tester, routinesPath);
      await harness.emitRoutines(tester, routineList: const []);

      await tester.tap(find.text(HomeCareRoutineCopy.newRoutine).last);
      await tester.pumpAndSettle();
      // Saving with nothing filled in points at everything missing.
      await tester.ensureVisible(find.text(AppCopy.householdSave));
      await tester.tap(find.text(AppCopy.householdSave));
      await tester.pumpAndSettle();
      expect(find.text(HomeCareRoutineCopy.missing(.noName)), findsOneWidget);
      expect(harness.routines.writes, isEmpty);

      await tester.enterText(
        find.descendant(
          of: find.ancestor(
            of: find.text(HomeCareRoutineCopy.routineName).first,
            matching: find.byType(NestTextField),
          ),
          matching: find.byType(EditableText),
        ),
        'Kitchen tidy',
      );
      await tester.tap(find.text('Kitchen').last);
      await tester.tap(find.text('Thandi Helper'));
      await tester.ensureVisible(
        find.text(HomeCareRoutineCopy.cadenceName(RoutineCadence.weekly)),
      );
      await tester.tap(
        find.text(HomeCareRoutineCopy.cadenceName(RoutineCadence.weekly)),
      );
      await tester.pumpAndSettle();
      final suggestion = find.text('Wipe the counters');
      await tester.ensureVisible(suggestion);
      await tester.tap(suggestion);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppCopy.householdSave));
      await tester.tap(find.text(AppCopy.householdSave));
      await tester.pumpAndSettle();

      expect(harness.routines.methods, ['saveRoutine']);
      final saved =
          harness.routines.writes.single.$2['routine']! as RoomRoutine;
      expect(saved.name, 'Kitchen tidy');
      expect(saved.roomId, 'kitchen');
      expect(saved.helperId, Fixtures.thandiMemberId);
      expect(saved.cadence, RoutineCadence.weekly);
      expect(saved.items.map((item) => item.text), ['Wipe the counters']);
      expect(saved.createdBy, Fixtures.samMemberId);
    });

    testWidgets('a routine opens to be changed, or deleted once confirmed', (
      tester,
    ) async {
      await open(tester, routinesPath);
      await harness.emitRoutines(
        tester,
        routineList: [RoutineFixtures.everyDay()],
      );
      await tester.tap(find.text('Kitchen, every day').last);
      await tester.pumpAndSettle();
      expect(find.text(HomeCareRoutineCopy.editRoutine), findsOneWidget);

      await tester.ensureVisible(find.text(HomeCareRoutineCopy.deleteRoutine));
      await tester.tap(find.text(HomeCareRoutineCopy.deleteRoutine));
      await tester.pumpAndSettle();
      expect(find.text(HomeCareRoutineCopy.deleteConfirm), findsOneWidget);
      await tester.tap(find.text(HomeCareRoutineCopy.deleteRoutine).last);
      await tester.pumpAndSettle();
      expect(harness.routines.methods, ['deleteRoutine']);
    });

    testWidgets('says plainly when the switch is off', (tester) async {
      await open(tester, routinesPath);
      harness.flags.emit({'homeCareRoutines': false});
      await tester.pumpAndSettle();
      expect(find.text(HomeCareCopy.switchedOffTitle), findsOneWidget);
    });
  });

  group('today’s rooms', () {
    testWidgets('a helper sees her rooms, big, and ticks as she goes', (
      tester,
    ) async {
      await open(tester, todayPath, asHelper: true);
      await harness.emitRoutines(
        tester,
        routineList: [RoutineFixtures.everyDay()],
      );
      expect(harness.routines.routinesAskedFor.last, Fixtures.thandiMemberId);
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Wipe the counters'), findsOneWidget);

      await tester.tap(find.text('Sweep the floor'));
      await tester.pumpAndSettle();
      expect(harness.routines.methods, ['setDoneItems']);
      expect(harness.routines.writes.single.$2['doneItemIds'], ['i2']);
      expect(harness.routines.writes.single.$2['by'], Fixtures.thandiMemberId);
    });

    testWidgets('a room with everything ticked says it is done, in words', (
      tester,
    ) async {
      await open(tester, todayPath, asHelper: true);
      final today = HouseholdClock('Africa/Johannesburg').today;
      final routine = RoutineFixtures.everyDay();
      await harness.emitRoutines(
        tester,
        routineList: [routine],
        ticks: [
          RoutineFixtures.tick(routine, today, ['i1', 'i2', 'i3']),
        ],
      );
      expect(find.text(HomeCareRoutineCopy.roomDone), findsOneWidget);
      expect(find.text(HomeCareRoutineCopy.done(3, 3)), findsOneWidget);
    });

    testWidgets('a parent sees everybody’s day, with whose each is', (
      tester,
    ) async {
      await open(tester, todayPath);
      await harness.emitRoutines(
        tester,
        routineList: [RoutineFixtures.everyDay()],
      );
      expect(
        find.text(HomeCareRoutineCopy.forHelper('Thandi Helper')),
        findsOneWidget,
      );
    });

    testWidgets('nothing on today says so', (tester) async {
      await open(tester, todayPath, asHelper: true);
      await harness.emitRoutines(tester, routineList: const []);
      expect(find.text(HomeCareRoutineCopy.nothingTodayTitle), findsOneWidget);
    });

    testWidgets('a helper’s own routine only: somebody else’s is not hers', (
      tester,
    ) async {
      await open(tester, todayPath, asHelper: true);
      await harness.emitRoutines(
        tester,
        routineList: [RoutineFixtures.everyDay(helperId: 'm-gogo')],
      );
      expect(find.text(HomeCareRoutineCopy.nothingTodayTitle), findsOneWidget);
    });

    testWidgets('a refused tick is said in words above the rooms', (
      tester,
    ) async {
      await open(tester, todayPath, asHelper: true);
      await harness.emitRoutines(
        tester,
        routineList: [RoutineFixtures.everyDay()],
      );
      harness.routines.failWritesWith = const PermissionDeniedFailure();
      await tester.tap(find.text('Wipe the counters'));
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
    });
  });

  test('the fixtures a routine screen is built from fall today', () {
    final routine = RoutineFixtures.everyDay();
    expect(routine, isA<RoomRoutine>());
  });
}
