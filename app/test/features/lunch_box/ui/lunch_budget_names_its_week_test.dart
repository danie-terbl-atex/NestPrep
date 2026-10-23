import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_budget_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_budget_strip.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// The meter and the board's spend line say which week they price
/// (lunch-box ADR-0019): a parent who has moved the board to next week reads
/// "Next week", never "This week" over next week's money.
void main() {
  late LunchPlanningHarness harness;

  setUp(() => harness = LunchPlanningHarness());
  tearDown(() => harness.close());

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(420, 2200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final premium = SubscriptionHarness(
      entitlement: Entitlement(
        premiumUntil: DateTime.now().add(const Duration(days: 30)),
      ),
    );
    await pumpScreen(
      tester,
      screen,
      providers: [...premium.providers, ...harness.providers],
    );
    harness.lunch.emit();
    harness.emitPlanning(
      prices: [const LunchPrice(id: 'grapes', cents: 1200, updatedBy: 'm')],
      budget: const LunchBudget(id: 'weekly', cents: 25000, updatedBy: 'm'),
    );
    await tester.pumpAndSettle();
  }

  /// The board moved on a week, and that week's plan answering.
  Future<void> toNextWeek(WidgetTester tester) async {
    harness.board.goToNextWeek();
    // The new window opens after the old one's cancel, which a widget test
    // only lets through with a real turn (lesson: give a widget test a real
    // turn after anything that awaits a stream subscription's cancel).
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    harness.lunch.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.ayandaId,
          week: LunchFixtures.week.next,
          slots: {
            LunchFixtures.key(1, LunchSlot.fruit): LunchPick.of(
              LunchFixtures.grapes,
            ),
          },
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the meter says "This week", then "Next week" once the board '
      'has moved on', (tester) async {
    await pump(tester, const LunchBudgetScreen());
    expect(find.text('This week'), findsWidgets);
    expect(find.text('Next week'), findsNothing);
    await toNextWeek(tester);
    expect(find.text('Next week'), findsOneWidget);
    expect(find.text('This week'), findsNothing);
  });

  testWidgets('the spend line on the board names the week it prices', (
    tester,
  ) async {
    await pump(tester, const Material(child: LunchBudgetStrip()));
    expect(find.text('This week'), findsOneWidget);
    await toNextWeek(tester);
    expect(find.text('Next week'), findsOneWidget);
    expect(find.text('This week'), findsNothing);
  });
}
