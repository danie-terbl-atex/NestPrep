import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_packed_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';
import '../../../support/test_flags.dart';

/// The V2 tools on the lunch board (lunch-box ADR-0006 to ADR-0008): gone
/// when their switches are off, each a way in when on; planning from the
/// pantry changes the picker and packs from it; today's box is marked
/// packed; and a premium household sees the week's spend.
void main() {
  late LunchPlanningHarness harness;

  tearDown(() => harness.close());

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  Future<void> pump(
    WidgetTester tester, {
    FeatureFlags flags = TestFlags.on,
    bool isPremium = false,
  }) async {
    harness = LunchPlanningHarness(flags: flags);
    tester.view.physicalSize = const Size(420 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final premium = SubscriptionHarness(
      entitlement: isPremium
          ? Entitlement(
              premiumUntil: DateTime.now().add(const Duration(days: 30)),
            )
          : Entitlement.free,
    );
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => LunchScreen(onSelectTab: (_) {}),
          ),
          for (final place in ['pantry', 'budget', 'picks'])
            GoRoute(
              path: '/households/:householdId/lunch/$place',
              builder: (context, state) => Text('opened $place'),
            ),
        ],
      ),
      providers: [...premium.providers, ...harness.providers],
    );
  }

  Future<void> arrive(
    WidgetTester tester, {
    List<LunchPantryEntry> pantry = const [],
    List<LunchPackedDay> packed = const [],
    List<LunchPrice> prices = const [],
    LunchBudget? budget,
  }) async {
    harness.lunch.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {key(2, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple)},
        ),
      ],
    );
    harness.emitPlanning(
      pantry: pantry,
      packed: packed,
      prices: prices,
      budget: budget,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with every switch off, the board is as it was', (tester) async {
    await pump(tester, flags: TestFlags.off);
    await arrive(tester);
    expect(find.text(LunchPlanningCopy.openPantry), findsNothing);
    expect(find.text(LunchPantryCopy.planFromPantry), findsNothing);
    expect(find.text(LunchPlanningCopy.openKidPicks), findsNothing);
  });

  testWidgets('with them on, each tool is a way in', (tester) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text(LunchPlanningCopy.openPantry));
    await tester.pumpAndSettle();
    expect(find.text('opened pantry'), findsOneWidget);
  });

  testWidgets('kid picks opens from the board', (tester) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text(LunchPlanningCopy.openKidPicks));
    await tester.pumpAndSettle();
    expect(find.text('opened picks'), findsOneWidget);
  });

  testWidgets('budget says it is premium, and opens for a premium household', (
    tester,
  ) async {
    await pump(tester, isPremium: true);
    await arrive(
      tester,
      prices: [const LunchPrice(id: 'apple', cents: 450, updatedBy: 'm-sam')],
      budget: const LunchBudget(id: 'weekly', cents: 25000, updatedBy: 'm'),
    );
    expect(find.text(LunchBudgetCopy.spentOf('R4.50', 'R250')), findsOneWidget);
    await tester.tap(find.text(LunchPlanningCopy.openBudget));
    await tester.pumpAndSettle();
    expect(find.text('opened budget'), findsOneWidget);
  });

  testWidgets('a free household sees budget marked premium', (tester) async {
    await pump(tester);
    await arrive(tester);
    expect(
      find.text(
        '${LunchPlanningCopy.openBudget} · ${LunchPlanningCopy.premiumHint}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('planning from the pantry puts what is there first in the '
      'picker, and says so', (tester) async {
    await pump(tester);
    await arrive(
      tester,
      pantry: [
        const LunchPantryEntry(id: 'grapes', portions: 3, updatedBy: 'm'),
      ],
    );
    await tester.tap(find.text(LunchPantryCopy.planFromPantry));
    await tester.pumpAndSettle();
    expect(find.text(LunchPantryCopy.fillFromPantry), findsOneWidget);

    await bringIntoView(
      tester,
      find.text(LunchCopy.addToSlot(LunchSlot.fruit)).first,
    );
    await tester.tap(find.text(LunchCopy.addToSlot(LunchSlot.fruit)).first);
    await tester.pumpAndSettle();
    expect(find.textContaining(LunchPantryCopy.inPantry(3)), findsOneWidget);
    expect(find.textContaining(LunchPantryCopy.notInPantry), findsOneWidget);
  });

  testWidgets('today’s box is marked packed, and can be undone', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      pantry: [
        const LunchPantryEntry(id: 'apple', portions: 2, updatedBy: 'm'),
      ],
    );
    await tester.tap(find.text(LunchPantryCopy.markPacked));
    await tester.pumpAndSettle();
    expect(harness.pantryRepository.packedWrites.single.takeFrom, {'apple': 1});
  });
}
