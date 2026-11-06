import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meal_week.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/recipes/model/recipe_meal_lines.dart';
import 'package:nestprep/features/recipes/model/recipe_scale.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_meal_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/recipe_fixtures.dart';

/// Friday 18 September 2026 in Johannesburg; its week starts Monday the 14th.
final _nowUtc = DateTime.utc(2026, 9, 18, 9);

Meal meal(String name, {String id = 'm1'}) =>
    Meal.named(id: id, name: name, addedBy: Fixtures.samMemberId);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeMealRepository repository;
  late MealPlanController controller;
  late StreamController<Map<int, List<String>>> packed;
  late List<String> packedWeeks;

  setUp(() {
    repository = FakeMealRepository();
    packed = StreamController.broadcast();
    packedWeeks = [];
    controller = MealPlanController(
      mealRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      watchPackedDays: (monday) {
        packedWeeks.add(monday.iso);
        return packed.stream;
      },
    );
  });

  tearDown(() async {
    controller.dispose();
    await packed.close();
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

  test('a picked recipe becomes its household meal, scaled to the family, '
      'and fills the slot', () async {
    await emit();
    final bobotie = RecipeFixtures.bobotie;
    await controller.setSlotFromRecipe('2_dinner', bobotie, familySize: 3);

    final added = repository.recipeMeals.single;
    expect(added.recipeId, bobotie.id);
    expect(added.name, bobotie.name);
    expect(added.addedBy, Fixtures.samMemberId);
    expect(
      added.ingredients,
      recipeMealLines(
        bobotie,
        RecipeScale(people: 3, servings: bobotie.servings),
      ),
    );
    expect(repository.writtenSlots.single.monday, '2026-09-14');
    expect(repository.writtenSlots.single.slots, {
      '2_dinner': Meal.idForRecipe(bobotie.id),
    });
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

  group('school lunches', () {
    test('put the children with a packed box on their day', () async {
      await emit();
      packed.add({
        1: [Fixtures.kidMemberId],
      });
      await pumpEventQueue();

      final days = weekOf().days;
      expect(days[0].schoolLunchFor, [Fixtures.kidMemberId]);
      expect(days[1].schoolLunchFor, isEmpty);
      expect(days[5].schoolLunchFor, isEmpty);
    });

    test('follow the week on show and start empty there', () async {
      await emit();
      packed.add({
        1: [Fixtures.kidMemberId],
      });
      await pumpEventQueue();

      controller.goToNextWeek();
      await pumpEventQueue();
      await emit();

      expect(packedWeeks, ['2026-09-14', '2026-09-21']);
      expect(weekOf().days[0].schoolLunchFor, isEmpty);
    });

    test('a refused lunch read leaves the meals showing', () async {
      packed.addError(const PermissionDeniedFailure());
      await emit(
        meals: [meal('Spaghetti', id: 'spag')],
        plan: const WeekPlan(id: '2026-09-14', slots: {'2_dinner': 'spag'}),
      );

      expect(weekOf().days[1].meals[MealSlot.dinner]?.name, 'Spaghetti');
    });
  });
}
