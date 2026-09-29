import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/kid_accounts/model/kid_day.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/household_fixtures.dart';
import '../../../support/kid_home_fixture.dart';

/// A kid device's home (accounts ADR-0003): the reads a kid may make, joined
/// into one day, and a refused read shown as what it is — a grown-up signed
/// this device out.
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

  test('waits for the household before opening anything dated', () async {
    expect(fixture.controller.day, isA<AsyncLoading<KidDay>>());
    expect(fixture.todos.tasksForMemberId, isNull);

    fixture.households.emitHousehold(Fixtures.household());
    await pumpEventQueue();

    expect(fixture.todos.tasksForMemberId, Fixtures.kidMemberId);
    expect(fixture.todos.completionsForMemberId, Fixtures.kidMemberId);
    expect(fixture.households.watchedMemberId, Fixtures.kidMemberId);
  });

  test("reads only this kid's chores, back to the overdue horizon", () async {
    await fixture.arrive();

    expect(fixture.todos.completionsFrom, KidHomeFixture.today.addDays(-7));
    expect(fixture.todos.completionsTo, KidHomeFixture.today);
    expect(fixture.meals.watchedWeeks, [KidHomeFixture.today.weekStart.iso]);
  });

  test(
    "today's jobs, and the ones left undone from before, overdue first",
    () async {
      await fixture.arrive(
        tasks: [
          KidHomeFixture.chore('bed', 'Make your bed'),
          KidHomeFixture.chore(
            'cat',
            'Feed the cat',
            due: CalendarDate(2026, 9, 27),
          ),
          KidHomeFixture.chore(
            'old',
            'Old job',
            due: CalendarDate(2026, 9, 26),
          ),
          KidHomeFixture.chore(
            'soon',
            'Tomorrow job',
            due: CalendarDate(2026, 9, 30),
          ),
        ],
        completions: [
          KidHomeFixture.done('old', on: CalendarDate(2026, 9, 26)),
        ],
      );

      final day = dayOf();
      expect(
        [for (final chore in day.chores) chore.task.title],
        ['Feed the cat', 'Make your bed'],
      );
      expect(day.chores.first.isOverdue(day.today), isTrue);
      expect(day.me.id, Fixtures.kidMemberId);
    },
  );

  test('counts what is done, and knows when everything is', () async {
    await fixture.arrive(
      tasks: [
        KidHomeFixture.chore('bed', 'Make your bed'),
        KidHomeFixture.chore('teeth', 'Brush teeth'),
      ],
      completions: [KidHomeFixture.done('bed')],
    );
    expect(dayOf().doneCount, 1);
    expect(dayOf().isAllDone, isFalse);

    fixture.todos.emitCompletions([
      KidHomeFixture.done('bed'),
      KidHomeFixture.done('teeth'),
    ]);
    await pumpEventQueue();
    expect(dayOf().isAllDone, isTrue);
  });

  test("names today's food from the week's plan", () async {
    await fixture.arrive(
      slots: {
        WeekPlan.slotKey(KidHomeFixture.today.weekday, MealSlot.lunch): 'pasta',
      },
    );

    final day = dayOf();
    expect(day.meals[MealSlot.lunch]?.name, 'Pasta bake');
    expect(day.meals[MealSlot.dinner], isNull);
    expect(day.hasFoodPlanned, isTrue);
  });

  test('ticks a job off as this kid and for this kid, and back on', () async {
    await fixture.arrive(tasks: [KidHomeFixture.chore('bed', 'Make your bed')]);
    final chore = dayOf().chores.single;

    await fixture.controller.toggle(chore);
    expect(fixture.todos.completed.single, (
      taskId: 'bed',
      date: KidHomeFixture.today,
      by: Fixtures.kidMemberId,
      forMember: Fixtures.kidMemberId,
    ));

    fixture.todos.emitCompletions([KidHomeFixture.done('bed')]);
    await pumpEventQueue();
    await fixture.controller.toggle(dayOf().chores.single);
    expect(fixture.todos.uncompleted.single.taskId, 'bed');
  });

  test('a refused tick is kept for the banner, not thrown', () async {
    await fixture.arrive(tasks: [KidHomeFixture.chore('bed', 'Make your bed')]);
    fixture.todos.failWritesWith = const UnavailableFailure();

    await fixture.controller.toggle(dayOf().chores.single);

    expect(fixture.controller.actionFailure, isA<UnavailableFailure>());
  });

  group('a device a parent signed out', () {
    const disconnected = KidSignInFailure(KidSignInProblem.deviceDisconnected);

    Matcher isDisconnected() => isA<AsyncFailure<KidDay>>().having(
      (state) => state.failure,
      'failure',
      isA<KidSignInFailure>().having(
        (failure) => failure.problem,
        'problem',
        disconnected.problem,
      ),
    );

    test('is told so when the rules start refusing its reads', () async {
      await fixture.arrive();
      fixture.todos.failTasksWith(const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(fixture.controller.day, isDisconnected());
    });

    test('and when its profile has been removed', () async {
      await fixture.arrive();
      fixture.households.emitMember(null);
      await pumpEventQueue();
      expect(fixture.controller.day, isDisconnected());
    });

    test('and when its session is no longer accepted', () async {
      fixture.households.failHouseholdWith(const SessionExpiredFailure());
      await pumpEventQueue();
      expect(fixture.controller.day, isDisconnected());
    });
  });

  test('any other failure is an error that can be retried', () async {
    fixture.households.failHouseholdWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(fixture.controller.day, isA<AsyncFailure<KidDay>>());

    await fixture.controller.retry();
    expect(fixture.controller.day, isA<AsyncLoading<KidDay>>());
    await fixture.arrive();
    expect(fixture.controller.day, isA<AsyncData<KidDay>>());
  });
}
