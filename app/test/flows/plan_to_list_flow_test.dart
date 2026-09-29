import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/data/meal_plan_grocery_source.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/state/grocery_plan_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/features/groceries/ui/grocery_plan_wording.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredient.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_plan_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/grocery_plan_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../support/fake_grocery_repository.dart';
import '../support/fake_meal_repository.dart';
import '../support/grocery_plan_fixtures.dart';
import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';

/// Groceries phase 2's flow line: fill a plan slot, and see what it needs on
/// the list — through the real meal source, the real controllers and the real
/// screens, with only Firestore faked.
///
/// A parent plans Spaghetti for Tuesday dinner on the meal plan. On the list,
/// the week's plans offer mince and onions for Tuesday dinner; they update the
/// list and both are on it, saying where they came from. Then they turn on
/// *keep the list in step*, clear the slot, and the two come off — while the
/// milk they typed themselves stays.

/// A Tuesday: the meal week and the lunch week are both Monday the 28th.
final _tuesday = DateTime.utc(2026, 9, 29, 7);
const _monday = '2026-09-28';
const _tuesdayDate = '2026-09-29';
const _tuesdayDinner = '2_dinner';

final _spaghetti =
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
        MealIngredient.typed(name: 'Onions', amount: 2),
      ],
    );

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeMealRepository meals;
  late FakeGroceryRepository groceries;
  final clock = HouseholdClock('Africa/Johannesburg', now: () => _tuesday);

  setUp(() {
    meals = FakeMealRepository();
    groceries = FakeGroceryRepository(echoPlanWrites: true);
  });

  tearDown(() async {
    await meals.close();
    await groceries.close();
  });

  Future<void> planTuesdayDinner(WidgetTester tester) async {
    final controller = MealPlanController(
      mealRepository: meals,
      householdClock: clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    await pumpScreen(
      tester,
      MealPlanScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<MealPlanController>.value(value: controller),
      ],
    );
    meals.emitMeals([_spaghetti]);
    meals.emitWeek(WeekPlan.empty(controller.weekStart));
    await tester.pumpAndSettle();

    final slot = find.descendant(
      of: find.byKey(const ValueKey(_tuesdayDate)),
      matching: find.text(AppCopy.mealSlotName('dinner')),
    );
    await tester.scrollUntilVisible(slot, 120);
    await tester.pumpAndSettle();
    await tester.tap(slot);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spaghetti'));
    await tester.pumpAndSettle();

    expect(meals.writtenSlots.single.monday, _monday);
    expect(meals.writtenSlots.single.slots, {_tuesdayDinner: 'spaghetti'});
    // Leave the meal plan, as the parent does, before opening the list.
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  }

  Future<void> openTheList(WidgetTester tester) async {
    final list = GroceryListController(
      groceryRepository: groceries,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      now: () => _tuesday,
    );
    final plans = GroceryPlanController(
      groceryRepository: groceries,
      sources: [MealPlanGrocerySource(meals)],
      wording: groceryPlanWording(Fixtures.view()),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      week: LunchWeek.planningFor(clock.today),
      canEdit: true,
      seesEverySource: true,
      now: () => _tuesday,
    );
    addTearDown(list.dispose);
    addTearDown(plans.dispose);
    await pumpScreen(
      tester,
      GroceryListScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<GroceryListController>.value(value: list),
        ChangeNotifierProvider<GroceryPlanController>.value(value: plans),
      ],
    );
    // What Firestore holds now: the slot the parent filled, and their milk.
    meals.emitMeals([_spaghetti]);
    meals.emitWeek(
      WeekPlan(id: _monday, slots: meals.writtenSlots.single.slots),
    );
    groceries
      ..emitSettings(groceries.settings)
      ..emitItems([typedItem('Milk')]);
    await tester.pumpAndSettle();
  }

  testWidgets('a filled slot’s ingredients reach the list, and leave with it', (
    tester,
  ) async {
    await planTuesdayDinner(tester);
    await openTheList(tester);

    expect(find.text(GroceryPlanCopy.needs(2)), findsOneWidget);
    await tester.tap(find.text(GroceryPlanCopy.review));
    await tester.pumpAndSettle();
    await tester.tap(find.text(GroceryPlanCopy.apply(2)));
    await tester.pumpAndSettle();

    expect(find.text('500 g · For Tuesday dinner'), findsOneWidget);
    expect(find.text('×2 · For Tuesday dinner'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);

    // Keep in step, then clear the slot: what the plan added comes off.
    await tester.tap(find.bySemanticsLabel(GroceryPlanCopy.open));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Switch))).pop();
    await tester.pumpAndSettle();

    meals.emitWeek(const WeekPlan(id: _monday));
    await tester.pumpAndSettle();

    expect(find.text('Mince'), findsNothing);
    expect(find.text('Onions'), findsNothing);
    expect(find.text('Milk'), findsOneWidget, reason: 'typed: never touched');
  });
}
