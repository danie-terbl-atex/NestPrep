import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_settings.dart';
import 'package:nestprep/features/groceries/ui/grocery_plan_content.dart';
import 'package:nestprep/features/groceries/ui/grocery_plan_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/grocery_plan_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/grocery_plan_fixtures.dart';
import '../../../support/grocery_plan_harness.dart';
import '../../../support/pump_screen.dart';

/// *From this week's plans* (groceries ADR-0002): all four states, and that
/// nothing is written but what a person left ticked.
void main() {
  late GroceryPlanHarness plans;
  late List<GroceryPlanDestination> destinations;

  setUp(() => destinations = []);

  Future<void> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    // In the test's own zone, so writes settle with the pumps.
    plans = GroceryPlanHarness();
    addTearDown(plans.close);
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: NestButton(
              label: 'open',
              onPressed: () => showGroceryPlanSheet(
                context: context,
                onPlan: destinations.add,
              ),
            ),
          ),
        ),
      ),
      providers: [plans.provider],
      brightness: brightness,
      textScale: scale,
    );
    await tester.tap(find.text('open'));
    // Not settled: while the plans load, the skeleton shimmers.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tapShown(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('holds its place while the plans load', (tester) async {
    await open(tester);
    expect(find.byType(NestLoadingView), findsOneWidget);
  });

  testWidgets('says what went wrong in words, with a way to try again', (
    tester,
  ) async {
    await open(tester);
    plans.meals.fail(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('nothing planned says how to plan, both ways', (tester) async {
    await open(tester);
    plans.open();
    await tester.pumpAndSettle();

    expect(find.text(GroceryPlanCopy.emptyTitle), findsOneWidget);
    await tapShown(tester, find.text(GroceryPlanCopy.planLunches));
    expect(destinations, [GroceryPlanDestination.lunch]);
  });

  testWidgets('unticking a line leaves it off the list', (tester) async {
    await open(tester);
    plans.open(
      mealNeeds: [
        GroceryPlanHarness.dinner('Bread', 2),
        GroceryPlanHarness.dinner('Mince', 2),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(GroceryPlanCopy.apply(2)), findsOneWidget);

    await tapShown(tester, find.text('Mince'));
    expect(find.text(GroceryPlanCopy.apply(1)), findsOneWidget);

    await tapShown(tester, find.text(GroceryPlanCopy.apply(1)));
    final creates = plans.repository.planChanges.single.changes.creates;
    expect([for (final create in creates) create.name], ['Bread']);
    expect(find.text(GroceryPlanCopy.title), findsNothing, reason: 'closed');
  });

  testWidgets('bought recently is offered unticked, and can be added again', (
    tester,
  ) async {
    await open(tester);
    plans.open(mealNeeds: [GroceryPlanHarness.dinner('Eggs', 2)]);
    plans.repository.emitItems([typedItem('Eggs', boughtAt: planNow)]);
    await tester.pumpAndSettle();

    expect(find.text(GroceryPlanCopy.recentlyBought), findsOneWidget);
    expect(find.text(GroceryPlanCopy.nothingChosen), findsOneWidget);
    await tapShown(tester, find.text('Eggs'));
    await tapShown(tester, find.text(GroceryPlanCopy.apply(1)));
    expect(
      plans.repository.planChanges.single.changes.creates.single.name,
      'Eggs',
    );
  });

  testWidgets('a changed amount and a cleared plan are offered as changes', (
    tester,
  ) async {
    await open(tester);
    plans.open(mealNeeds: [GroceryPlanHarness.dinner('Mince', 2)]);
    plans.repository.emitItems([
      plannedItem('Mince', note: 'For Monday dinner'),
      plannedItem('Rice'),
      typedItem('Milk'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(GroceryPlanCopy.toRefresh), findsOneWidget);
    expect(find.text(GroceryPlanCopy.nowNoAmount), findsOneWidget);
    expect(find.text(GroceryPlanCopy.toRemove), findsOneWidget);
    expect(find.text('Milk'), findsNothing, reason: 'typed: not the plans’');

    await tapShown(tester, find.text(GroceryPlanCopy.apply(2)));
    final changes = plans.repository.planChanges.single.changes;
    expect(changes.refreshes.single.note, 'For Tuesday dinner');
    expect(changes.removals, ['plan-$planWeek-rice']);
  });

  testWidgets('usually in the house takes a line out, and back', (
    tester,
  ) async {
    await open(tester);
    plans.open(mealNeeds: [GroceryPlanHarness.dinner('Salt', 2)]);
    await tester.pumpAndSettle();

    await tapShown(
      tester,
      find.bySemanticsLabel(GroceryPlanCopy.markStapleFor('Salt')),
    );
    expect(plans.repository.stapleWrites.single.isStaple, isTrue);
    expect(find.text(GroceryPlanCopy.staples), findsOneWidget);

    await tapShown(
      tester,
      find.bySemanticsLabel(GroceryPlanCopy.putBack('Salt')),
    );
    expect(plans.repository.stapleWrites.last.isStaple, isFalse);
    expect(find.text(GroceryPlanCopy.toAdd), findsOneWidget);
  });

  testWidgets('keeping in step is one switch, and says who turned it on', (
    tester,
  ) async {
    await open(tester);
    plans.open();
    await tester.pumpAndSettle();

    await tapShown(tester, find.byType(Switch));
    expect(plans.repository.keepInStepWrites, [true]);
    expect(find.text(GroceryPlanCopy.turnedOnBy('Sam Parent')), findsOneWidget);
  });

  testWidgets('tick all and untick all', (tester) async {
    await open(tester);
    plans.open(mealNeeds: [GroceryPlanHarness.dinner('Bread', 2)]);
    plans.repository.emitItems([typedItem('Eggs', boughtAt: planNow)]);
    plans.meals.emit([
      GroceryPlanHarness.dinner('Bread', 2),
      GroceryPlanHarness.dinner('Eggs', 2),
    ]);
    await tester.pumpAndSettle();

    await tapShown(tester, find.text(GroceryPlanCopy.selectAll));
    expect(find.text(GroceryPlanCopy.apply(2)), findsOneWidget);
    await tapShown(tester, find.text(GroceryPlanCopy.selectNone));
    expect(find.text(GroceryPlanCopy.nothingChosen), findsOneWidget);
  });

  testWidgets('every group, in dark at 200% on 360 wide, without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await open(tester, brightness: Brightness.dark, scale: 2);
    plans.open(
      settings: const GroceryPlanSettings(staples: ['salt']),
      mealNeeds: [
        GroceryPlanHarness.dinner('Full cream milk', 2),
        GroceryPlanHarness.dinner('Mince', 3),
        GroceryPlanHarness.dinner('Salt', 3),
      ],
      lunchNeeds: [GroceryPlanHarness.lunch('Wholewheat bread rolls', 5)],
    );
    plans.repository.emitItems([plannedItem('Mince'), plannedItem('Rice')]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Every group, scrolled through to the last, stays inside the sheet.
    for (final group in [
      GroceryPlanCopy.toAdd,
      GroceryPlanCopy.toRefresh,
      GroceryPlanCopy.toRemove,
      GroceryPlanCopy.staples,
    ]) {
      await tester.scrollUntilVisible(
        find.text(group),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull, reason: group);
    }
  });
}
