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

/// The week's planner (lunch-box ADR-0022): every whole-week action in one
/// card under the week's name — *Fill the week*, planning from the pantry
/// (ADR-0006), *Plan my week from Checkers* (ADR-0012, premium) and the
/// week's spend (ADR-0007, premium) — and none of it for somebody who may
/// only look.
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

  Finder planMyWeek() => find.text(PlanWeekCopy.entryTitle('this week'));

  testWidgets('planning from the pantry puts what is there first in the '
      'picker, and says so', (tester) async {
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
    expect(find.text(LunchPantryCopy.fillFromPantry), findsOneWidget);

    final fruit = find.text(LunchCopy.addToSlot(LunchSlot.fruit)).first;
    await bringIntoView(tester, fruit);
    await tester.tap(fruit);
    await tester.pumpAndSettle();
    expect(find.textContaining(LunchPantryCopy.inPantry(3)), findsOneWidget);
    expect(find.textContaining(LunchPantryCopy.notInPantry), findsOneWidget);
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

  testWidgets('plan my week from Checkers names the week, says it is '
      'premium, and opens the paywall for a free household', (tester) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    await bringIntoView(tester, planMyWeek());
    expect(find.text(PlanWeekCopy.premiumTag), findsOneWidget);
    await tester.tap(planMyWeek());
    await tester.pumpAndSettle();
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.aiPlanning)),
      findsOneWidget,
    );
    expect(find.text('opened plan-week'), findsNothing);
  });

  testWidgets('plan my week opens for a premium household', (tester) async {
    harness = await LunchBoardRig.pump(tester, isPremium: true);
    await arrive(tester);
    await bringIntoView(tester, planMyWeek());
    expect(find.text(PlanWeekCopy.premiumTag), findsNothing);
    await tester.tap(planMyWeek());
    await tester.pumpAndSettle();
    expect(find.text('opened plan-week'), findsOneWidget);
  });

  testWidgets('somebody who may only look sees the week, and no planner', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester, isPremium: true, canEdit: false);
    await arrive(
      tester,
      prices: [const LunchPrice(id: 'apple', cents: 450, updatedBy: 'm-sam')],
    );
    expect(find.text(LunchCopy.planWholeWeek), findsNothing);
    expect(find.text(LunchCopy.fillWeek), findsNothing);
    expect(find.text(LunchPantryCopy.planFromPantry), findsNothing);
    expect(planMyWeek(), findsNothing);
    expect(find.text(LunchBudgetCopy.spentOnly('R4.50')), findsNothing);
    expect(find.text(LunchCopy.thisWeek), findsWidgets);
  });
}
