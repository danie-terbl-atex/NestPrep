import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/kid_accounts/model/kid_areas.dart';
import 'package:nestprep/features/kid_accounts/model/kid_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/household_fixtures.dart';
import '../../../support/kid_home_fixture.dart';

/// A kid device shows what its kid profile's grant opens, and follows the
/// grant when a parent changes it (accounts ADR-0004) — the client's half of
/// what `kid_device_grant.rules.test.ts` proves on the server.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late KidHomeFixture fixture;

  setUp(() => fixture = KidHomeFixture());
  tearDown(() => fixture.close());

  KidDay dayOf() {
    final state = fixture.controller.day;
    expect(state, isA<AsyncData<KidDay>>());
    return (state as AsyncData<KidDay>).value;
  }

  Member kidWith(AccessGrant? access, {String role = 'kid'}) =>
      Fixtures.kid.copyWith(access: access, roleName: role);

  AccessGrant kidDefaultsWith(HouseholdArea area, AccessLevel level) =>
      AccessDefaults.kid.withLevel(area, level);

  test('the kid defaults open the jobs, the ticking, the food and their own '
      'lunch box', () async {
    await fixture.arrive();
    expect(
      dayOf().areas,
      const KidAreas(chores: true, canTick: true, food: true, lunch: true),
    );
    // Only the one plan the `own` grant opens — theirs, this week.
    expect(fixture.lunches.watchedPlans, ['${Fixtures.kidMemberId}_2026-W40']);
  });

  test('their lunch box today is the one a grown-up packed', () async {
    await fixture.arrive(
      lunchSlots: {
        // Tuesday 29 September is weekday 2.
        '2_main': const LunchPick(itemId: 'wrap', name: 'Chicken wrap'),
        '3_main': const LunchPick(itemId: 'pie', name: 'Tomorrow’s pie'),
      },
    );
    final box = dayOf().lunchBox!;
    expect(box[LunchSlot.main]?.name, 'Chicken wrap');
    expect(box.filledCount, 1);
  });

  test(
    'a grant with no lunch closes the lunch box and keeps the rest',
    () async {
      await fixture.arrive();
      fixture.households.emitMember(
        kidWith(kidDefaultsWith(HouseholdArea.lunch, AccessLevel.none)),
      );
      await pumpEventQueue();
      final day = dayOf();
      expect(day.areas.lunch, isFalse);
      expect(day.lunchBox, isNull);
      expect(day.areas.food, isTrue);
    },
  );

  test('a lunch read the rules refuse closes only the lunch box', () async {
    await fixture.arrive();
    fixture.lunches.failPlanWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(
      dayOf().areas,
      const KidAreas(chores: true, canTick: true, food: true),
    );
  });

  test('todos at view shows the jobs and does not tick them', () async {
    await fixture.arrive();
    fixture.households.emitMember(
      kidWith(kidDefaultsWith(HouseholdArea.todos, AccessLevel.view)),
    );
    await pumpEventQueue();
    fixture.todos
      ..emitTasks([KidHomeFixture.chore('dishes', 'Dishes')])
      ..emitRoutines(const [])
      ..emitCompletions(const []);
    await pumpEventQueue();

    final day = dayOf();
    expect(day.areas.chores, isTrue);
    expect(day.areas.canTick, isFalse);
    expect(day.chores.single.task.title, 'Dishes');
  });

  test(
    'a grant narrowed to no meals closes the food and keeps the jobs',
    () async {
      await fixture.arrive(tasks: [KidHomeFixture.chore('dishes', 'Dishes')]);
      fixture.households.emitMember(
        kidWith(kidDefaultsWith(HouseholdArea.meals, AccessLevel.none)),
      );
      await pumpEventQueue();
      // The jobs reopen with the new grant; the food does not.
      fixture.todos
        ..emitTasks([KidHomeFixture.chore('dishes', 'Dishes')])
        ..emitRoutines(const [])
        ..emitCompletions(const []);
      await pumpEventQueue();

      final day = dayOf();
      expect(day.areas.food, isFalse);
      expect(day.hasFoodPlanned, isFalse);
      expect(day.chores, hasLength(1));
    },
  );

  test(
    'no grant, or a profile that is no longer a kid, shows nothing',
    () async {
      await fixture.arrive();
      fixture.households.emitMember(kidWith(null));
      await pumpEventQueue();
      expect(dayOf().areas.showsAnything, isFalse);

      fixture.households.emitMember(
        kidWith(AccessDefaults.kid, role: 'parent'),
      );
      await pumpEventQueue();
      expect(dayOf().areas, KidAreas.nothing);
    },
  );

  test('an area the rules refuse before the profile says so is closed, '
      'not a signed-out device', () async {
    await fixture.arrive();
    fixture.todos.failTasksWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    // Only the refused part closes; the food stays, and nothing says
    // "signed out".
    expect(
      dayOf().areas,
      const KidAreas(chores: false, canTick: false, food: true, lunch: true),
    );
    expect(dayOf().hasFoodPlanned, isFalse);

    // The profile catches up with the same answer, and nothing reopens.
    final before = fixture.todos.tasksForWatched;
    fixture.households.emitMember(
      kidWith(kidDefaultsWith(HouseholdArea.todos, AccessLevel.none)),
    );
    await pumpEventQueue();
    expect(fixture.todos.tasksForWatched, before);
    expect(dayOf().areas.chores, isFalse);

    // A parent opens the jobs again, and they come back.
    fixture.households.emitMember(Fixtures.kid);
    await pumpEventQueue();
    expect(fixture.todos.tasksForWatched, before + 1);
  });

  test('the same grant arriving again reopens nothing', () async {
    await fixture.arrive(tasks: [KidHomeFixture.chore('dishes', 'Dishes')]);
    final before = fixture.todos.tasksForWatched;
    fixture.households.emitMember(Fixtures.kid);
    await pumpEventQueue();
    expect(fixture.todos.tasksForWatched, before);
    expect(dayOf().chores, hasLength(1));
  });
}
