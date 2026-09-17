import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meal_week.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_meal_repository.dart';
import '../../../support/household_fixtures.dart';

/// Friday 18 September 2026 in Johannesburg; its week starts Monday the 14th.
final _nowUtc = DateTime.utc(2026, 9, 18, 9);

Meal meal(String name, {String id = 'm1'}) =>
    Meal.named(id: id, name: name, addedBy: Fixtures.samMemberId);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeMealRepository repository;
  late MealPlanController controller;

  setUp(() {
    repository = FakeMealRepository();
    controller = MealPlanController(
      mealRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  MealWeek weekOf() {
    final state = controller.week;
    expect(state, isA<AsyncData<MealWeek>>());
    return (state as AsyncData<MealWeek>).value;
  }

  Future<void> emit({List<Meal> meals = const [], WeekPlan? plan}) async {
    repository.emitMeals(meals);
    repository.emitWeek(plan ?? WeekPlan.empty(controller.weekStart));
    await pumpEventQueue();
  }

  test('opens on the household"s current week, starting Monday', () {
    expect(controller.today.iso, '2026-09-18');
    expect(controller.weekStart.iso, '2026-09-14');
    expect(repository.watchedWeeks, ['2026-09-14']);
  });

  test('stays loading until both reads have answered', () async {
    expect(controller.week, isA<AsyncLoading<MealWeek>>());
    repository.emitMeals([]);
    await pumpEventQueue();
    expect(controller.week, isA<AsyncLoading<MealWeek>>());
    repository.emitWeek(WeekPlan.empty(controller.weekStart));
    await pumpEventQueue();
    expect(controller.week, isA<AsyncData<MealWeek>>());
  });

  test('resolves each slot against the library', () async {
    await emit(
      meals: [meal('Spaghetti', id: 'spag')],
      plan: const WeekPlan(id: '2026-09-14', slots: {'2_dinner': 'spag'}),
    );
    // Tuesday is the second day of the week.
    final tuesday = weekOf().days[1];
    expect(tuesday.date.iso, '2026-09-15');
    expect(tuesday.meals[MealSlot.dinner]?.name, 'Spaghetti');
    expect(tuesday.meals[MealSlot.lunch], isNull);
    expect(weekOf().days, hasLength(7));
  });

  test(
    'a slot naming a meal that is gone reads as empty, not as a crash',
    () async {
      await emit(
        meals: [],
        plan: const WeekPlan(id: '2026-09-14', slots: {'2_dinner': 'deleted'}),
      );
      expect(weekOf().days[1].meals[MealSlot.dinner], isNull);
    },
  );

  test('moving a week reopens that read with the new week', () async {
    controller.goToNextWeek();
    await pumpEventQueue();
    expect(controller.weekStart.iso, '2026-09-21');
    expect(repository.watchedWeeks.last, '2026-09-21');
  });

  test('filling a slot writes only that slot', () async {
    await emit(meals: [meal('Spaghetti', id: 'spag')]);
    await controller.setSlot('2_dinner', 'spag');

    expect(repository.writtenSlots.single.monday, '2026-09-14');
    expect(repository.writtenSlots.single.slots, {'2_dinner': 'spag'});
  });

  test('clearing a slot empties it rather than removing the week', () async {
    await emit();
    await controller.clearSlot('2_dinner');
    expect(repository.writtenSlots.single.slots, {'2_dinner': ''});
  });

  test('typing a new name adds it to the library and fills the slot', () async {
    await emit();
    await controller.setSlotByName('2_dinner', '  Spaghetti ');

    expect(repository.addedMeals.single, 'Spaghetti');
    expect(repository.writtenSlots.single.slots.values.single, 'meal-0');
  });

  test(
    'typing a name the household has used before reuses that meal',
    () async {
      final existing = meal('Spaghetti', id: 'spag');
      repository.knownMeals.add(existing);
      await emit(meals: [existing]);

      await controller.setSlotByName('2_dinner', 'spaghetti');
      expect(repository.knownMeals, hasLength(1));
      expect(repository.writtenSlots.single.slots.values.single, 'spag');
    },
  );

  test('refuses to fill a slot with nothing', () async {
    await emit();
    await controller.setSlotByName('2_dinner', '   ');
    expect(repository.writtenSlots, isEmpty);
  });

  test('copying last week fills only the empty slots', () async {
    repository.storedWeeks['2026-09-07'] = const WeekPlan(
      id: '2026-09-07',
      slots: {'2_dinner': 'spag', '4_dinner': 'curry'},
    );
    controller.goToWeek(CalendarDate.parse('2026-09-14'));
    await emit(
      plan: const WeekPlan(id: '2026-09-14', slots: {'2_dinner': 'pizza'}),
    );

    await controller.copyLastWeek();
    expect(repository.writtenSlots.single.slots, {'4_dinner': 'curry'});
  });

  test('copying with overwrite replaces what is there', () async {
    repository.storedWeeks['2026-09-07'] = const WeekPlan(
      id: '2026-09-07',
      slots: {'2_dinner': 'spag'},
    );
    await emit(
      plan: const WeekPlan(id: '2026-09-14', slots: {'2_dinner': 'pizza'}),
    );

    await controller.copyLastWeek(overwrite: true);
    expect(repository.writtenSlots.single.slots, {'2_dinner': 'spag'});
  });

  test('copying an empty week writes nothing at all', () async {
    await emit();
    await controller.copyLastWeek();
    expect(repository.writtenSlots, isEmpty);
    expect(controller.isCopying, isFalse);
  });

  test(
    'deleting a meal clears it from the weeks either side as well',
    () async {
      await emit(meals: [meal('Spaghetti', id: 'spag')]);
      await controller.deleteMeal('spag');

      expect(repository.deletedMeals.single.mealId, 'spag');
      expect(repository.deletedMeals.single.weeks, [
        '2026-09-07',
        '2026-09-14',
        '2026-09-21',
      ]);
    },
  );

  test('a refused write becomes copy, and clears', () async {
    await emit();
    repository.failWritesWith = const PermissionDeniedFailure();
    await controller.setSlot('2_dinner', 'spag');
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());

    controller.dismissActionFailure();
    expect(controller.actionFailure, isNull);
  });

  test('a read that fails becomes a failure state with a way back', () async {
    repository.failMealsWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.week, isA<AsyncFailure<MealWeek>>());

    await controller.retry();
    expect(controller.week, isA<AsyncLoading<MealWeek>>());
  });
}
