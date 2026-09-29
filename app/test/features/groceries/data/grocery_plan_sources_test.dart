import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/data/lunch_plan_grocery_source.dart';
import 'package:nestprep/features/groceries/data/meal_plan_grocery_source.dart';
import 'package:nestprep/features/groceries/model/grocery_amount.dart';
import 'package:nestprep/features/groceries/model/grocery_need.dart';
import 'package:nestprep/features/groceries/model/grocery_need_reason.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/lunch_box/data/lunch_week_reader.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredient.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_lunch_repository.dart';
import '../../../support/fake_meal_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

Meal _spaghetti() =>
    Meal.named(
      id: 'spaghetti',
      name: 'Spaghetti',
      addedBy: Fixtures.samMemberId,
    ).copyWith(
      ingredients: [
        MealIngredient.typed(
          name: 'Mince',
          amount: 500,
          unit: IngredientUnit.gram,
        ),
        MealIngredient.typed(name: 'Onions', amount: 1),
        MealIngredient.typed(name: 'Salt'),
      ],
    );

/// The first two `GrocerySuggestionSource`s (groceries ADR-0004): the week's
/// meals and the week's lunch boxes, as needs.
void main() {
  group('the meal plan', () {
    test('every ingredient of every planned slot, with the slot as reason', () {
      final plan = WeekPlan(
        id: LunchFixtures.week.monday.iso,
        slots: {
          WeekPlan.slotKey(2, MealSlot.dinner): 'spaghetti',
          WeekPlan.slotKey(4, MealSlot.dinner): 'spaghetti',
          WeekPlan.slotKey(3, MealSlot.lunch): 'gone',
        },
      );
      final needs = MealPlanGrocerySource.needsOf([_spaghetti()], plan);

      expect(
        needs,
        hasLength(6),
        reason: 'three lines, twice; a deleted meal adds none',
      );
      expect(needs.first.name, 'Mince');
      expect(needs.first.amount, const GroceryAmount(500, IngredientUnit.gram));
      expect(
        needs.first.reason,
        const MealPlanReason(
          isoWeekday: 2,
          slot: MealSlot.dinner,
          mealName: 'Spaghetti',
        ),
      );
      expect(needs[2].amount, isNull, reason: 'salt has no amount');
    });

    test('a meal nobody described needs nothing', () {
      final plan = WeekPlan(
        id: 'w',
        slots: {WeekPlan.slotKey(1, MealSlot.dinner): 'plain'},
      );
      final plain = Meal.named(id: 'plain', name: 'Toast', addedBy: 'm');
      expect(MealPlanGrocerySource.needsOf([plain], plan), isEmpty);
    });

    test(
      'reads the library and the week, live, under the meals grant',
      () async {
        final meals = FakeMealRepository();
        addTearDown(meals.close);
        final source = MealPlanGrocerySource(meals);
        expect(source.area, HouseholdArea.meals);

        final emitted = <List<GroceryNeed>>[];
        final subscription = source
            .watchNeeds(Fixtures.householdId, LunchFixtures.week)
            .listen(emitted.add);
        addTearDown(subscription.cancel);

        meals.emitMeals([_spaghetti()]);
        await pumpEventQueue();
        expect(emitted, isEmpty, reason: 'waits for the week too');

        meals.emitWeek(
          WeekPlan(
            id: LunchFixtures.week.monday.iso,
            slots: {WeekPlan.slotKey(1, MealSlot.dinner): 'spaghetti'},
          ),
        );
        await pumpEventQueue();
        expect(emitted.single, hasLength(3));
        expect(meals.watchedWeeks, [LunchFixtures.week.monday.iso]);
      },
    );
  });

  group('the lunch boxes', () {
    test('one need per item, counted in boxes across every child', () async {
      final lunches = FakeLunchRepository();
      addTearDown(lunches.close);
      final source = LunchPlanGrocerySource(LunchWeekReader(lunches));
      expect(source.area, HouseholdArea.lunch);

      final emitted = <List<GroceryNeed>>[];
      final subscription = source
          .watchNeeds(Fixtures.householdId, LunchFixtures.week)
          .listen(emitted.add);
      addTearDown(subscription.cancel);

      final apple = LunchPick.of(LunchFixtures.apple);
      lunches
        ..emitItems([LunchFixtures.apple])
        ..emitPlans([
          LunchFixtures.plan(
            LunchFixtures.lwaziId,
            slots: {
              LunchFixtures.key(1, LunchSlot.fruit): apple,
              LunchFixtures.key(2, LunchSlot.fruit): apple,
            },
          ),
          LunchFixtures.plan(
            LunchFixtures.ayandaId,
            slots: {LunchFixtures.key(1, LunchSlot.fruit): apple},
          ),
        ]);
      await pumpEventQueue();

      final need = emitted.last.single;
      expect(need.name, 'Apple slices');
      expect(need.amount, isNull, reason: 'a box is counted, never converted');
      expect(
        need.reason,
        const LunchPlanReason(
          boxes: 3,
          childIds: [LunchFixtures.lwaziId, LunchFixtures.ayandaId],
        ),
      );
    });

    test('a refusal reaches the reader as a failure, not silence', () async {
      final lunches = FakeLunchRepository();
      addTearDown(lunches.close);
      final errors = <Object>[];
      final subscription = LunchPlanGrocerySource(LunchWeekReader(lunches))
          .watchNeeds(Fixtures.householdId, LunchFixtures.week)
          .listen((_) {}, onError: errors.add);
      addTearDown(subscription.cancel);

      lunches.failItemsWith(const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(errors.single, isA<PermissionDeniedFailure>());
    });
  });
}
