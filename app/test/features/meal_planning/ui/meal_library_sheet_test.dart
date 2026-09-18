import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_library_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_meal_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The library everything is picked from, and the only place a meal is deleted.
/// Deleting one clears every slot that used it, in every week — which is why it
/// asks first. It was at zero.
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
        now: () => DateTime.utc(2026, 9, 18, 6),
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> open(
    WidgetTester tester, {
    List<Meal> library = const [],
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
    );
    repository.emitMeals(library);
    repository.emitWeek(WeekPlan.empty(controller.weekStart));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Meal meal(String id, String name) =>
      Meal.named(id: id, name: name, addedBy: Fixtures.samMemberId);

  testWidgets('a household that has typed nothing is told so', (tester) async {
    await open(tester);
    expect(find.text(AppCopy.mealsEmptyTitle), findsOneWidget);
  });

  testWidgets('every meal the household has typed is listed', (tester) async {
    await open(
      tester,
      library: [meal('m1', 'Spaghetti'), meal('m2', 'Chicken curry')],
    );

    expect(find.text('Spaghetti'), findsOneWidget);
    expect(find.text('Chicken curry'), findsOneWidget);
  });

  testWidgets('deleting asks first, and takes no for an answer', (
    tester,
  ) async {
    await open(tester, library: [meal('m1', 'Spaghetti')]);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.mealsDeleteConfirm), findsOneWidget);
    expect(
      find.textContaining(AppCopy.mealsDeleteBody),
      findsOneWidget,
      reason: 'it has to say that every week loses it, not just this one',
    );

    await tester.tap(find.text(AppCopy.householdCancel));
    await tester.pumpAndSettle();

    expect(repository.deletedMeals, isEmpty);
  });

  group('renaming', () {
    Finder fieldLabelled(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(NestTextField),
      ),
      matching: find.byType(TextField),
    );

    testWidgets('a typo can be fixed, and every week that used it follows', (
      tester,
    ) async {
      await open(tester, library: [meal('m1', 'Spagetti')]);

      await tester.tap(find.text('Spagetti'));
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.mealsRename), findsWidgets);

      await tester.enterText(
        fieldLabelled(AppCopy.mealsPickTitle),
        'Spaghetti',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
      await tester.pumpAndSettle();

      final renamed = repository.renamedMeals.single;
      expect(renamed.mealId, 'm1');
      expect(renamed.name, 'Spaghetti');
    });

    testWidgets('saving the same name is not offered', (tester) async {
      await open(tester, library: [meal('m1', 'Spaghetti')]);

      await tester.tap(find.text('Spaghetti'));
      await tester.pumpAndSettle();

      final save = tester.widget<NestButton>(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      expect(
        save.onPressed,
        isNull,
        reason: 'a rename to the same name is a write that changes nothing',
      );
    });

    testWidgets('closing without saving renames nothing', (tester) async {
      await open(tester, library: [meal('m1', 'Spaghetti')]);

      await tester.tap(find.text('Spaghetti'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(NestTextField))).pop();
      await tester.pumpAndSettle();

      expect(repository.renamedMeals, isEmpty);
    });
  });

  testWidgets('and deletes when it is confirmed', (tester) async {
    await open(tester, library: [meal('m1', 'Spaghetti')]);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, AppCopy.mealsDelete));
    await tester.pumpAndSettle();

    expect(repository.deletedMeals.single.mealId, 'm1');
  });
}
