import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_settings.dart';
import 'package:nestprep/features/groceries/ui/grocery_plan_prompt.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/grocery_plan_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/grocery_list_harness.dart';
import '../../../support/grocery_plan_harness.dart';

/// The list with the week's plans beside it (groceries ADR-0002): the prompt,
/// the way into the sheet, and what an item the plans put there says.
void main() {
  testWidgets('an empty list still offers what the plans need', (tester) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems(const []);
    h.plans.open(
      mealNeeds: [GroceryPlanHarness.dinner('Bread', 2)],
      lunchNeeds: [GroceryPlanHarness.lunch('Apples', 5)],
    );
    await tester.pumpAndSettle();

    expect(find.text(GroceryPlanCopy.needs(2)), findsOneWidget);
    expect(find.text(AppCopy.groceriesEmptyTitle), findsOneWidget);
    expect(h.plans.repository.planChanges, isEmpty, reason: 'it only asks');
  });

  testWidgets('review opens the sheet with each line and its reasons', (
    tester,
  ) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems(const []);
    h.plans.open(mealNeeds: [GroceryPlanHarness.dinner('Bread', 2)]);
    await tester.pumpAndSettle();

    await tester.tap(find.text(GroceryPlanCopy.review));
    await tester.pumpAndSettle();

    expect(find.text(GroceryPlanCopy.toAdd), findsOneWidget);
    expect(find.text('For Tuesday dinner'), findsOneWidget);
    expect(find.text(GroceryPlanCopy.apply(1)), findsOneWidget);
  });

  testWidgets('kept in step, the prompt says so instead of counting', (
    tester,
  ) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems(const []);
    h.plans.open(settings: const GroceryPlanSettings(keepInStep: true));
    await tester.pumpAndSettle();

    expect(find.text(GroceryPlanCopy.inStep), findsOneWidget);
  });

  testWidgets('nothing to say, no prompt — the header button stays', (
    tester,
  ) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems([groceryItem('Milk', id: 'milk')]);
    h.plans.open();
    await tester.pumpAndSettle();

    expect(find.text(GroceryPlanCopy.review), findsNothing);
    expect(find.bySemanticsLabel(GroceryPlanCopy.open), findsOneWidget);
  });

  testWidgets('an item from the plans says which plans, not who added it', (
    tester,
  ) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems([
      groceryItem('Bread', id: 'b').copyWith(
        quantity: '2 loaves',
        sourceKey: 'bread',
        sourceWeek: '2026-W38',
        sourceNote: 'For 5 lunches + Tuesday dinner',
      ),
    ]);
    h.plans.open();
    await tester.pumpAndSettle();

    expect(
      find.text('2 loaves · For 5 lunches + Tuesday dinner'),
      findsOneWidget,
    );
  });

  testWidgets('the empty sheet leads to planning meals', (tester) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems(const []);
    h.plans.open();
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(GroceryPlanCopy.open));
    await tester.pumpAndSettle();
    expect(find.text(GroceryPlanCopy.emptyTitle), findsOneWidget);

    await tester.tap(find.text(GroceryPlanCopy.planMeals));
    await tester.pumpAndSettle();
    expect(h.selectedTabs, [HouseholdTab.meals]);
  });

  testWidgets('a refused keep-in-step change is shown as copy', (tester) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems(const []);
    h.plans.repository.failWritesWith = const PermissionDeniedFailure();
    h.plans.open(
      settings: const GroceryPlanSettings(keepInStep: true),
      mealNeeds: [GroceryPlanHarness.dinner('Mince', 2)],
    );
    await tester.pumpAndSettle();
    h.plans.lunches.emit(const []);
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
  });

  testWidgets('with the prompt, in dark at 200% on 360 wide', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final h = GroceryListHarness();
    await h.pump(tester, brightness: Brightness.dark, scale: 2);
    h.repository.emitItems([groceryItem('Full cream milk', id: 'milk')]);
    h.plans.open(mealNeeds: [GroceryPlanHarness.dinner('Bread', 2)]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(GroceryPlanCopy.needs(1)), findsOneWidget);
    // At 200% the prompt fills the first screen; the list is under it.
    await tester.scrollUntilVisible(
      find.text('Full cream milk'),
      200,
      scrollable: find
          .ancestor(
            of: find.byType(GroceryPlanPrompt),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty, with the prompt, in dark at 200% on 360 wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final h = GroceryListHarness();
    await h.pump(tester, brightness: Brightness.dark, scale: 2);
    h.repository.emitItems(const []);
    h.plans.open(mealNeeds: [GroceryPlanHarness.dinner('Bread', 2)]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(GroceryPlanCopy.needs(1)), findsOneWidget);
  });
}
