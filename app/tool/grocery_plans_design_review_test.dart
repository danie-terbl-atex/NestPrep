import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nestprep/features/groceries/model/grocery_amount.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_need.dart';
import 'package:nestprep/features/groceries/model/grocery_need_reason.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_settings.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredient.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_plan_screen.dart';
import 'package:nestprep/shared/copy/grocery_plan_copy.dart';
import 'package:nestprep/shared/copy/meal_ingredient_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_grocery_repository.dart';
import '../test/support/fake_meal_repository.dart';
import '../test/support/grocery_plan_fixtures.dart';
import '../test/support/grocery_plan_harness.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Groceries phase 2 in the design-review press: *From this week's plans*
/// with every group it can show, and *What goes in it* for a meal — light and
/// dark. Pictures to look at, not assertions: regenerate with
///
///     flutter test tool/grocery_plans_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  GroceryNeed dinner(String name, int day, [GroceryAmount? amount]) =>
      GroceryNeed(
        name: name,
        amount: amount,
        reason: MealPlanReason(
          isoWeekday: day,
          slot: MealSlot.dinner,
          mealName: 'Spaghetti bolognese',
        ),
      );

  GroceryNeed lunch(String name, int boxes) => GroceryNeed(
    name: name,
    reason: LunchPlanReason(
      boxes: boxes,
      childIds: const [Fixtures.kidMemberId],
    ),
  );

  Future<void> plansSheet(WidgetTester tester, Brightness brightness) async {
    final repository = FakeGroceryRepository();
    addTearDown(repository.close);
    final list = GroceryListController(
      groceryRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      now: () => planNow,
    );
    addTearDown(list.dispose);
    final plans = GroceryPlanHarness();
    addTearDown(plans.close);

    await captureScreen(
      tester,
      'grocery-plans-${brightness.name}',
      screen: GroceryListScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<GroceryListController>.value(value: list),
        plans.provider,
      ],
      brightness: brightness,
      emit: () async {
        final onList = [
          typedItem('Milk'),
          plannedItem('Mince', quantity: '500 g'),
          typedItem(
            'Eggs',
            boughtAt: planNow.subtract(const Duration(days: 1)),
          ),
        ];
        repository.emitItems(<GroceryItem>[...onList]);
        plans.open(
          settings: const GroceryPlanSettings(staples: ['salt']),
          mealNeeds: [
            dinner('Bread', 2, const GroceryAmount(1, IngredientUnit.loaf)),
            dinner('Mince', 2, const GroceryAmount(500, IngredientUnit.gram)),
            dinner('Mince', 4, const GroceryAmount(500, IngredientUnit.gram)),
            dinner(
              'Tinned tomatoes',
              4,
              const GroceryAmount(2, IngredientUnit.tin),
            ),
            dinner('Salt', 2),
            dinner('Eggs', 5, const GroceryAmount(6)),
          ],
          lunchNeeds: [lunch('Bread', 5), lunch('Apples', 5), lunch('Milk', 2)],
        );
        plans.repository.emitItems(onList);
      },
      act: () async {
        await tester.tap(find.text(GroceryPlanCopy.review));
      },
    );
  }

  Future<void> ingredients(WidgetTester tester, Brightness brightness) async {
    final repository = FakeMealRepository();
    addTearDown(repository.close);
    final controller = MealPlanController(
      mealRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => planNow),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    addTearDown(controller.dispose);
    final spaghetti =
        Meal.named(
          id: 'm1',
          name: 'Spaghetti bolognese',
          addedBy: Fixtures.samMemberId,
        ).copyWith(
          ingredients: [
            MealIngredient.typed(
              name: 'Mince',
              amount: 500,
              unit: IngredientUnit.gram,
            ),
            MealIngredient.typed(name: 'Onions', amount: 2),
            MealIngredient.typed(
              name: 'Tinned tomatoes',
              amount: 2,
              unit: IngredientUnit.tin,
            ),
            MealIngredient.typed(
              name: 'Olive oil',
              amount: 2,
              unit: IngredientUnit.tablespoon,
            ),
            MealIngredient.typed(
              name: 'Spaghetti',
              amount: 1,
              unit: IngredientUnit.pack,
            ),
          ],
        );

    await captureScreen(
      tester,
      'meal-ingredients-${brightness.name}',
      screen: MealPlanScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<MealPlanController>.value(value: controller),
      ],
      brightness: brightness,
      emit: () async {
        repository.emitMeals([spaghetti]);
        repository.emitWeek(
          WeekPlan(
            id: controller.weekStart.iso,
            slots: const {'2_dinner': 'm1'},
          ),
        );
      },
      act: () async {
        await tester.tap(find.byIcon(LucideIcons.bookOpen));
        await tester.pumpAndSettle();
        await tester.tap(
          find.bySemanticsLabel(
            MealIngredientCopy.openFor('Spaghetti bolognese'),
          ),
        );
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('from this week’s plans — ${brightness.name}', (tester) async {
      await plansSheet(tester, brightness);
    });
    testWidgets('what goes in a meal — ${brightness.name}', (tester) async {
      await ingredients(tester, brightness);
    });
  }
}
