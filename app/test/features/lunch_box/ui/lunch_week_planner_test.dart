import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/lunch_board_rig.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/plan_the_week.dart';

/// The week's planner (lunch-box ADR-0022, ADR-0033): one *Plan the week*
/// button whose chooser offers Twig (ADR-0012, premium, first for Premium),
/// the boxes yourself (ADR-0020) and the pantry (ADR-0006) while it is
/// planned from; the pantry switch and the week's spend (ADR-0007, premium)
/// beside it — and none of it for somebody who may only look.
void main() {
  late LunchPlanningHarness harness;

  tearDown(() => harness.close());

  Future<void> arrive(
    WidgetTester tester, {
    List<LunchPantryEntry> pantry = const [],
    List<LunchPrice> prices = const [],
    LunchBudget? budget,
  }) async {
    harness.lunch.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {
            LunchFixtures.key(2, LunchSlot.fruit): LunchPick.of(
              LunchFixtures.apple,
            ),
          },
        ),
      ],
    );
    harness.emitPlanning(pantry: pantry, prices: prices, budget: budget);
    await tester.pumpAndSettle();
  }

  Finder twig() => find.text(PlanWeekCopy.entryTitle);
  Finder boxes() => find.text(LunchCopy.planWithBoxes);
  Finder fromPantry() => find.text(LunchPantryCopy.fillFromPantry);

  testWidgets('planning from the pantry puts what is there first in the '
      'picker, and adds filling from it to Plan the week', (tester) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(
      tester,
      pantry: [
        const LunchPantryEntry(id: 'grapes', portions: 3, updatedBy: 'm'),
      ],
    );
    await tapPlanTheWeek(tester);
    expect(fromPantry(), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await bringIntoView(tester, find.text(LunchPantryCopy.planFromPantry));
    await tester.tap(find.text(LunchPantryCopy.planFromPantry));
    await tester.pumpAndSettle();
    await tapPlanTheWeek(tester);
    expect(fromPantry(), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final fruit = find.text(LunchCopy.addToSlot(LunchSlot.fruit)).first;
    await bringIntoView(tester, fruit);
    await tester.tap(fruit);
    await tester.pumpAndSettle();
    expect(find.textContaining(LunchPantryCopy.inPantry(3)), findsOneWidget);
    expect(find.textContaining(LunchPantryCopy.notInPantry), findsOneWidget);
  });

  testWidgets('filling from the pantry, chosen in Plan the week, packs the '
      'empty days on the board', (tester) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(
      tester,
      pantry: [
        const LunchPantryEntry(id: 'grapes', portions: 3, updatedBy: 'm'),
      ],
    );
    await bringIntoView(tester, find.text(LunchPantryCopy.planFromPantry));
    await tester.tap(find.text(LunchPantryCopy.planFromPantry));
    await tester.pumpAndSettle();
    await planTheWeekWith(tester, fromPantry());
    expect(harness.lunch.repository.writtenPicks, isNotEmpty);
  });

  testWidgets('a premium household reads the week’s spend in the planner', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester, isPremium: true);
    await arrive(
      tester,
      prices: [const LunchPrice(id: 'apple', cents: 450, updatedBy: 'm-sam')],
      budget: const LunchBudget(id: 'weekly', cents: 25000, updatedBy: 'm'),
    );
    final spend = find.text(LunchBudgetCopy.spentOf('R4.50', 'R250'));
    await bringIntoView(tester, spend);
    await tester.tap(spend);
    await tester.pumpAndSettle();
    expect(find.text('opened budget'), findsOneWidget);
  });

  testWidgets('the planner holds one way to plan the week, and the chooser '
      'names the week it plans', (tester) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    expect(planTheWeekButton, findsOneWidget);
    expect(twig(), findsNothing);
    expect(boxes(), findsNothing);
    await tapPlanTheWeek(tester);
    expect(
      find.text(LunchCopy.planWeekSheetTitle('this week')),
      findsOneWidget,
    );
  });

  testWidgets('a free household is offered its own boxes first, then Twig '
      'marked premium, whose paywall opens before anything else', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    await tapPlanTheWeek(tester);
    expect(
      tester.getTopLeft(boxes()).dy,
      lessThan(tester.getTopLeft(twig()).dy),
    );
    expect(find.text(PlanWeekCopy.premiumTag), findsOneWidget);
    await tester.tap(twig());
    await tester.pumpAndSettle();
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.aiPlanning)),
      findsOneWidget,
    );
    expect(find.text('opened plan-week'), findsNothing);
  });

  testWidgets('a premium household meets Twig first, untagged, and it opens '
      'Plan my week', (tester) async {
    harness = await LunchBoardRig.pump(tester, isPremium: true);
    await arrive(tester);
    await tapPlanTheWeek(tester);
    expect(
      tester.getTopLeft(twig()).dy,
      lessThan(tester.getTopLeft(boxes()).dy),
    );
    expect(find.text(PlanWeekCopy.premiumTag), findsNothing);
    await tester.tap(twig());
    await tester.pumpAndSettle();
    expect(find.text('opened plan-week'), findsOneWidget);
  });

  testWidgets('picking the boxes yourself opens Fill the week', (tester) async {
    harness = await LunchBoardRig.pump(tester, isPremium: true);
    await arrive(tester);
    await planTheWeekWith(tester, boxes());
    expect(find.text('opened fill-week'), findsOneWidget);
  });

  testWidgets('the chooser fits a 360-wide phone in dark at 200% text', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    tester.view.physicalSize = const Size(360 * 3, 2600 * 3);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tapPlanTheWeek(tester);
    expect(tester.takeException(), isNull);
    expect(twig(), findsOneWidget);
    expect(boxes(), findsOneWidget);
  });

  testWidgets('somebody who may only look sees the week, and no planner', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester, isPremium: true, canEdit: false);
    await arrive(
      tester,
      prices: [const LunchPrice(id: 'apple', cents: 450, updatedBy: 'm-sam')],
    );
    expect(planTheWeekButton, findsNothing);
    expect(find.text(LunchPantryCopy.planFromPantry), findsNothing);
    expect(find.text(LunchBudgetCopy.spentOnly('R4.50')), findsNothing);
    expect(find.text(LunchCopy.thisWeek), findsWidgets);
  });
}
