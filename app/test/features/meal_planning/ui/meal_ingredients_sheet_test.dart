import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredient.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_library_sheet.dart';
import 'package:nestprep/shared/copy/meal_ingredient_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_meal_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// What goes in a meal (meal-planning ADR-0002), reached from the library: the
/// way the grocery list learns what a planned meal needs.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeMealRepository repository;
  late MealPlanController controller;

  setUp(() {
    repository = FakeMealRepository();
    controller = MealPlanController(
      mealRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => DateTime.utc(2026, 9, 29, 6),
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  final spaghetti =
      Meal.named(
        id: 'm1',
        name: 'Spaghetti',
        addedBy: Fixtures.thandiMemberId,
      ).copyWith(
        ingredients: [
          MealIngredient.typed(
            name: 'Mince',
            amount: 500,
            unit: IngredientUnit.gram,
          ),
        ],
      );

  Future<void> openIngredients(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => NestButton(
          label: 'open',
          onPressed: () => showMealLibrarySheet(context: context),
        ),
      ),
      providers: [
        ChangeNotifierProvider<MealPlanController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
    repository.emitMeals([spaghetti]);
    repository.emitWeek(WeekPlan.empty(controller.weekStart));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(MealIngredientCopy.count(1)), findsOneWidget);
    await tester.tap(
      find.bySemanticsLabel(MealIngredientCopy.openFor('Spaghetti')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapShown(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('lists what goes in it, and adds a line with an amount', (
    tester,
  ) async {
    await openIngredients(tester);
    expect(find.text(MealIngredientCopy.title('Spaghetti')), findsOneWidget);
    expect(find.text('Mince · 500 g'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, MealIngredientCopy.nameHint),
      'Tinned tomatoes',
    );
    await tester.enterText(
      find.widgetWithText(TextField, MealIngredientCopy.amountHint),
      '2',
    );
    await tapShown(tester, find.text('tin'));
    await tapShown(tester, find.text(MealIngredientCopy.add));
    expect(find.text('Tinned tomatoes · 2 tins'), findsOneWidget);

    await tapShown(tester, find.text(MealIngredientCopy.save));
    final written = repository.ingredientWrites.single;
    expect(written.mealId, 'm1');
    expect(
      [for (final line in written.ingredients) line.name],
      ['Mince', 'Tinned tomatoes'],
    );
    expect(written.ingredients.last.unit, IngredientUnit.tin);
    expect(written.ingredients.last.amount, 2);
  });

  testWidgets('an amount that is not a number is said, and nothing is added', (
    tester,
  ) async {
    await openIngredients(tester);
    await tester.enterText(
      find.widgetWithText(TextField, MealIngredientCopy.nameHint),
      'Onions',
    );
    await tester.enterText(
      find.widgetWithText(TextField, MealIngredientCopy.amountHint),
      'a few',
    );
    await tapShown(tester, find.text(MealIngredientCopy.add));

    expect(find.text(MealIngredientCopy.amountInvalid), findsOneWidget);
    expect(find.textContaining('Onions ·'), findsNothing);
  });

  testWidgets('a line comes off, and saving writes what is left', (
    tester,
  ) async {
    await openIngredients(tester);
    await tapShown(
      tester,
      find.bySemanticsLabel(MealIngredientCopy.remove('Mince')),
    );
    expect(find.text(MealIngredientCopy.empty), findsOneWidget);

    await tapShown(tester, find.text(MealIngredientCopy.save));
    expect(repository.ingredientWrites.single.ingredients, isEmpty);
  });

  testWidgets('in dark at 200% on 360 wide, without overflow', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await openIngredients(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(MealIngredientCopy.add),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });
}
