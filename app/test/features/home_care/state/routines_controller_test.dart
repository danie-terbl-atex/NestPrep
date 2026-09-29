import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/home_care_access.dart';
import 'package:nestprep/features/home_care/model/home_care_board.dart';
import 'package:nestprep/features/home_care/model/routine/room_routine.dart';
import 'package:nestprep/features/home_care/model/routine/routine_board.dart';
import 'package:nestprep/features/home_care/model/routine/routine_draft.dart';
import 'package:nestprep/features/home_care/state/routines_controller.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_home_care_v2.dart';
import '../../../support/home_care_routine_fixtures.dart';
import '../../../support/household_fixtures.dart';

/// The routines' controller (home-care ADR-0004): two live reads and the
/// shell's rooms as one board, scoped by the grant, and every tick a write of
/// the whole day's list in the viewer's name.
void main() {
  final tuesday = CalendarDate(2026, 9, 29);
  late FakeRoutineRepository routines;

  const family = HomeCareAccess(
    level: AccessLevel.edit,
    viewerMemberId: Fixtures.samMemberId,
  );
  const cleaner = HomeCareAccess(
    level: AccessLevel.own,
    viewerMemberId: Fixtures.thandiMemberId,
  );

  AsyncState<HomeCareBoard> home() => AsyncData(
    HomeCareBoard(
      jobs: const [],
      rooms: RoutineFixtures.rooms,
      products: const [],
      members: [Fixtures.sam, Fixtures.thandi],
    ),
  );

  RoutinesController controllerFor(HomeCareAccess access) {
    final controller = RoutinesController(
      routineRepository: routines,
      householdId: Fixtures.householdId,
      today: tuesday,
      access: access,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  setUp(() => routines = FakeRoutineRepository());
  tearDown(() => routines.close());

  RoutineBoard boardOf(RoutinesController controller) =>
      (controller.board as AsyncData<RoutineBoard>).value;

  test('asks for everything for family, this week of ticks', () {
    controllerFor(family);
    expect(routines.routinesAskedFor, [null]);
    expect(routines.ticksAskedFor.single.helperId, isNull);
    expect(routines.ticksAskedFor.single.from, CalendarDate(2026, 9, 28));
    expect(routines.ticksAskedFor.single.to, CalendarDate(2026, 10, 4));
  });

  test('asks for exactly her own for a helper holding own', () {
    controllerFor(cleaner);
    expect(routines.routinesAskedFor, [Fixtures.thandiMemberId]);
    expect(routines.ticksAskedFor.single.helperId, Fixtures.thandiMemberId);
  });

  test('shows nothing until both reads and the rooms have answered', () async {
    final controller = controllerFor(family);
    routines.emitRoutines([RoutineFixtures.kitchenDaily(firstDate: tuesday)]);
    routines.emitTicks(const []);
    await pumpEventQueue();
    expect(controller.board, isA<AsyncLoading<RoutineBoard>>());

    controller.follow(family, home());
    final board = boardOf(controller);
    expect(board.routines, hasLength(1));
    expect(board.rooms, RoutineFixtures.rooms);
    expect(board.today, tuesday);
  });

  test(
    'a read that fails is the board’s failure, and retry reads again',
    () async {
      final controller = controllerFor(family)..follow(family, home());
      routines.failRoutinesWith(const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(controller.board, isA<AsyncFailure<RoutineBoard>>());

      await controller.retry();
      expect(routines.routinesAskedFor, hasLength(2));
      expect(controller.board, isA<AsyncLoading<RoutineBoard>>());
    },
  );

  test('a grant moving to own asks again, for her own', () async {
    final controller = controllerFor(family)..follow(family, home());
    controller.follow(cleaner, home());
    await pumpEventQueue();
    expect(routines.routinesAskedFor, [null, Fixtures.thandiMemberId]);
  });

  test('nobody without home care is shown anything', () {
    final controller = controllerFor(
      const HomeCareAccess(level: AccessLevel.none, viewerMemberId: 'm-kid'),
    );
    expect(controller.board, isA<AsyncFailure<RoutineBoard>>());
    expect(routines.routinesAskedFor, isEmpty);
  });

  test('ticking writes the day’s whole list, in the viewer’s name', () async {
    final controller = controllerFor(cleaner)..follow(cleaner, home());
    final kitchen = RoutineFixtures.kitchenDaily(firstDate: tuesday);
    routines.emitRoutines([kitchen]);
    routines.emitTicks([
      RoutineFixtures.tick(kitchen, tuesday, ['i1']),
    ]);
    await pumpEventQueue();

    final visit = boardOf(controller).visitOf(kitchen, tuesday)!;
    await controller.toggle(visit, 'i2');
    expect(routines.methods, ['setDoneItems']);
    expect(routines.writes.single.$2, {
      'routineId': 'kitchen-daily',
      'day': tuesday,
      'doneItemIds': ['i1', 'i2'],
      'by': Fixtures.thandiMemberId,
    });
  });

  test('saving stamps who made it; a refusal is kept for the banner', () async {
    final controller = controllerFor(family)..follow(family, home());
    final draft = RoutineDraft.startingOn(tuesday)
        .withName('Kitchen')
        .withRoom('kitchen')
        .withHelper(Fixtures.thandiMemberId)
        .withItemAdded('Wipe');
    await controller.save(draft);
    final saved = routines.writes.single.$2['routine']! as RoomRoutine;
    expect(saved.createdBy, Fixtures.samMemberId);

    routines.failWritesWith = const PermissionDeniedFailure();
    await controller.delete('kitchen-daily');
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    controller.dismissActionFailure();
    expect(controller.actionFailure, isNull);
  });
}
