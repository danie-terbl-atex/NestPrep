import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_budget_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_prices_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Budget mode's screens (lunch-box ADR-0007): locked for a free household,
/// and for a premium one the meter, each child's week in money, a cheaper
/// swap that is made in one tap, and the prices behind it all.
void main() {
  late LunchPlanningHarness harness;

  setUp(() => harness = LunchPlanningHarness());
  tearDown(() => harness.close());

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);
  LunchPrice price(String itemId, int cents, [int portions = 1]) =>
      LunchPrice(id: itemId, cents: cents, portions: portions, updatedBy: 'm');

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    bool isPremium = true,
    Brightness brightness = Brightness.light,
    double scale = 1,
    Size size = const Size(420, 2200),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final premium = SubscriptionHarness(
      entitlement: isPremium
          ? Entitlement(
              premiumUntil: DateTime.now().add(const Duration(days: 30)),
            )
          : Entitlement.free,
    );
    await pumpScreen(
      tester,
      screen,
      providers: [...premium.providers, ...harness.providers],
      brightness: brightness,
      textScale: scale,
    );
  }

  Future<void> arrive(WidgetTester tester, {LunchBudget? budget}) async {
    harness.lunch.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.ayandaId,
          slots: {
            key(2, LunchSlot.fruit): LunchPick.of(LunchFixtures.grapes),
            key(3, LunchSlot.fruit): LunchPick.of(LunchFixtures.grapes),
            key(3, LunchSlot.snack): LunchPick.of(LunchFixtures.biltong),
          },
        ),
      ],
    );
    harness.emitPlanning(
      prices: [price('grapes', 1200), price('apple', 450)],
      budget: budget,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a free household sees what budget mode does, and premium', (
    tester,
  ) async {
    await pump(tester, const LunchBudgetScreen(), isPremium: false);
    await arrive(tester);
    expect(find.text(LunchBudgetCopy.lockedTitle), findsOneWidget);
    expect(find.text(LunchBudgetCopy.seePremium), findsOneWidget);
    expect(find.text(LunchBudgetCopy.thisWeek), findsNothing);
  });

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester, const LunchBudgetScreen());
    await tester.pump();
    expect(find.text(LunchBudgetCopy.title), findsOneWidget);
    expect(find.text(LunchBudgetCopy.thisWeek), findsNothing);
  });

  testWidgets('shows a failure in words, with a retry', (tester) async {
    await pump(tester, const LunchBudgetScreen());
    harness.budgetRepository.failPricesWith(const UnavailableFailure());
    harness.lunch.emit();
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
  });

  testWidgets(
    'the week against its budget, gently, and at least when unpriced',
    (tester) async {
      await pump(tester, const LunchBudgetScreen());
      await arrive(
        tester,
        budget: const LunchBudget(id: 'weekly', cents: 2500, updatedBy: 'm'),
      );
      expect(
        find.text(LunchBudgetCopy.spentOf('R24.00', 'R25')),
        findsOneWidget,
      );
      expect(find.text(LunchBudgetCopy.nearly('R1.00')), findsOneWidget);
      expect(find.text(LunchBudgetCopy.unpriced(1)), findsOneWidget);
      expect(find.text(LunchBudgetCopy.basketTitle), findsOneWidget);
      expect(find.text(LunchBudgetCopy.basketBuy(2)), findsOneWidget);
      expect(find.text(LunchBudgetCopy.basketCovers(2)), findsOneWidget);
    },
  );

  testWidgets('a budget is set from the meter, in whole cents', (tester) async {
    await pump(tester, const LunchBudgetScreen());
    await arrive(tester);
    expect(find.text(LunchBudgetCopy.noBudget), findsOneWidget);
    await tester.tap(find.text(LunchBudgetCopy.setBudget));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '250');
    await tester.pumpAndSettle();
    await tester.tap(find.text(LunchBudgetCopy.saveBudget));
    await tester.pumpAndSettle();
    expect(harness.budgetRepository.setBudgets.single.cents, 25000);
  });

  testWidgets('a cheaper swap is made in one tap, across the week to come', (
    tester,
  ) async {
    await pump(tester, const LunchBudgetScreen());
    await arrive(tester);
    harness.board.selectChild(LunchFixtures.ayandaId);
    await tester.pumpAndSettle();
    expect(
      find.text(LunchBudgetCopy.swapLine('Grapes', 'Apple slices')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text(LunchBudgetCopy.swap));
    await tester.tap(find.text(LunchBudgetCopy.swap));
    await tester.pumpAndSettle();
    final write = harness.lunch.repository.writtenPicks.single;
    expect(write.picks.keys, [
      key(2, LunchSlot.fruit),
      key(3, LunchSlot.fruit),
    ]);
    expect(write.picks.values.every((pick) => pick!.itemId == 'apple'), isTrue);
  });

  testWidgets('prices are listed unpriced first, and set per pack', (
    tester,
  ) async {
    await pump(tester, const LunchPricesScreen());
    await arrive(tester);
    expect(find.text(LunchBudgetCopy.noPrice), findsWidgets);
    await tester.tap(find.text('Biltong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LunchBudgetCopy.byPack));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '42');
    await tester.enterText(find.byType(TextField).last, '8');
    await tester.pumpAndSettle();
    expect(find.text(LunchBudgetCopy.worksOutAt('R5.25')), findsOneWidget);
    await tester.tap(find.text(LunchBudgetCopy.savePrice));
    await tester.pumpAndSettle();
    final saved = harness.budgetRepository.setPrices.single;
    expect((saved.itemId, saved.cents, saved.portions), ('biltong', 4200, 8));
  });

  testWidgets('renders in dark and at 200% text on a small phone', (
    tester,
  ) async {
    await pump(
      tester,
      const LunchBudgetScreen(),
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    await arrive(
      tester,
      budget: const LunchBudget(id: 'weekly', cents: 2000, updatedBy: 'm'),
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
