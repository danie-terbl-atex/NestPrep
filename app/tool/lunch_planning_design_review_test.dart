import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/state/lunch_choose_controller.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_budget_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_choose_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_kid_picks_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_pantry_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_prices_screen.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_lunch_planning.dart';
import '../test/support/fake_lunch_repository.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/lunch_fixtures.dart';
import '../test/support/lunch_planning_harness.dart';
import '../test/support/pump_subscriptions.dart';
import 'review_press.dart';

/// Lunch-box's V2 tools in the design-review press (lunch-box ADR-0006 to
/// ADR-0008): the board with them on, the pantry, budget mode (and its lock),
/// the prices, kid picks, and the chooser a child sees — light and dark, and
/// the chooser at 200% text. Regenerate with
///
///     flutter test tool/lunch_planning_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final library = LunchSeedCatalogue.itemsFor(Fixtures.samMemberId);
  String id(String key) => LunchSeedCatalogue.idFor(key);
  LunchPick seed(String key) =>
      LunchPick.of(library.firstWhere((item) => item.seedKey == key));
  String at(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);

  final lwaziWeek = LunchFixtures.plan(
    LunchFixtures.lwaziId,
    slots: {
      at(2, LunchSlot.main): seed('chicken-mayo'),
      at(2, LunchSlot.fruit): seed('apple'),
      at(2, LunchSlot.snack): seed('biltong'),
      at(3, LunchSlot.main): seed('pasta-salad'),
      at(3, LunchSlot.fruit): seed('grapes'),
      at(4, LunchSlot.fruit): seed('grapes'),
      at(4, LunchSlot.snack): seed('popcorn'),
    },
  );

  LunchPantryEntry stock(String key, int portions) =>
      LunchPantryEntry(id: id(key), portions: portions, updatedBy: 'm');
  LunchPrice price(String key, int cents, [int portions = 1]) =>
      LunchPrice(id: id(key), cents: cents, portions: portions, updatedBy: 'm');

  final choices =
      LunchChoices.none(
        childId: LunchFixtures.lwaziId,
        week: LunchFixtures.week,
      ).copyWith(
        options: {
          at(2, LunchSlot.treat): [seed('muffin'), seed('popcorn')],
          at(3, LunchSlot.veg): [seed('carrot-sticks'), seed('cucumber')],
          at(3, LunchSlot.snack): [seed('biltong'), seed('popcorn')],
          at(5, LunchSlot.main): [
            seed('cheese-rolls'),
            seed('pasta-salad'),
            seed('chicken-mayo'),
          ],
          at(5, LunchSlot.fruit): [
            seed('apple'),
            seed('banana'),
            seed('naartjie'),
          ],
        },
        chosen: {at(3, LunchSlot.snack): id('biltong')},
      );

  Future<void> capturePlanning(
    WidgetTester tester,
    String name,
    Widget screen, {
    Brightness brightness = Brightness.light,
    bool isPremium = true,
    Future<void> Function(LunchPlanningHarness harness)? act,
  }) async {
    final harness = LunchPlanningHarness();
    addTearDown(harness.close);
    final premium = SubscriptionHarness(
      entitlement: isPremium
          ? Entitlement(
              premiumUntil: DateTime.now().add(const Duration(days: 30)),
            )
          : Entitlement.free,
    );
    await captureScreen(
      tester,
      name,
      screen: screen,
      providers: [...premium.providers, ...harness.providers],
      emit: () async {
        harness.lunch.emit(items: library, plans: [lwaziWeek]);
        harness.emitPlanning(
          pantry: [
            stock('apple', 1),
            stock('grapes', 4),
            stock('biltong', 6),
            stock('popcorn', 0),
            stock('pasta-salad', 2),
          ],
          prices: [
            price('chicken-mayo', 4800, 6),
            price('apple', 3500, 10),
            price('grapes', 1200),
            price('biltong', 6500, 5),
            price('popcorn', 900),
            price('naartjie', 400),
            price('banana', 350),
          ],
          budget: const LunchBudget(id: 'weekly', cents: 25000, updatedBy: 'm'),
          choices: [choices],
        );
      },
      brightness: brightness,
      act: act == null ? null : () => act(harness),
    );
  }

  Future<void> captureChooser(
    WidgetTester tester,
    String name, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final plans = FakeLunchRepository();
    final options = FakeLunchChoicesRepository();
    final controller = LunchChooseController(
      lunchRepository: plans,
      choicesRepository: options,
      householdId: Fixtures.householdId,
      childId: LunchFixtures.lwaziId,
    );
    addTearDown(() async {
      controller.dispose();
      await plans.close();
      await options.close();
    });
    await captureScreen(
      tester,
      name,
      screen: const LunchChooseScreen(childName: 'Lwazi'),
      providers: [
        ChangeNotifierProvider<LunchChooseController>.value(value: controller),
      ],
      emit: () async {
        controller.follow(today: LunchFixtures.today, week: LunchFixtures.week);
        await tester.pump();
        plans.emitPlan(
          LunchFixtures.plan(
            LunchFixtures.lwaziId,
            slots: {at(3, LunchSlot.snack): seed('biltong')},
          ),
        );
        options.emitChoices(
          choices.copyWith(
            options: {
              for (final entry in choices.options.entries)
                if (entry.key.startsWith('3_')) entry.key: entry.value,
            },
          ),
        );
      },
      brightness: brightness,
      textScale: textScale,
    );
  }

  final board = LunchScreen(onSelectTab: (_) {});

  testWidgets(
    'the board with the V2 tools, planning from the pantry',
    (tester) => capturePlanning(
      tester,
      'lunch-planning-board-light',
      board,
      act: (harness) async {
        harness.pantry.setPlanningFromPantry(isOn: true);
        await tester.pump();
        await tester.drag(screenList(), const Offset(0, -420));
      },
    ),
  );

  for (final (brightness, suffix) in [
    (Brightness.light, 'light'),
    (Brightness.dark, 'dark'),
  ]) {
    testWidgets(
      'the pantry, $suffix',
      (tester) => capturePlanning(
        tester,
        'lunch-pantry-$suffix',
        const LunchPantryScreen(),
        brightness: brightness,
      ),
    );
    testWidgets(
      'budget mode, $suffix',
      (tester) => capturePlanning(
        tester,
        'lunch-budget-$suffix',
        const LunchBudgetScreen(),
        brightness: brightness,
      ),
    );
    testWidgets(
      'kid picks, $suffix',
      (tester) => capturePlanning(
        tester,
        'lunch-kid-picks-$suffix',
        const LunchKidPicksScreen(),
        brightness: brightness,
      ),
    );
    testWidgets(
      'the chooser, $suffix',
      (tester) => captureChooser(
        tester,
        'lunch-choose-$suffix',
        brightness: brightness,
      ),
    );
  }

  testWidgets(
    'budget mode, locked for a free household',
    (tester) => capturePlanning(
      tester,
      'lunch-budget-locked-light',
      const LunchBudgetScreen(),
      isPremium: false,
    ),
  );

  testWidgets(
    'the prices',
    (tester) => capturePlanning(
      tester,
      'lunch-prices-light',
      const LunchPricesScreen(),
    ),
  );

  testWidgets(
    'the chooser, dark at 200% text',
    (tester) => captureChooser(
      tester,
      'lunch-choose-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
    ),
  );
}
