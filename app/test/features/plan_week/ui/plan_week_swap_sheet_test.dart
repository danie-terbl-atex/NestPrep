import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_swap_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Swapping one compartment of the planned week (lunch-box ADR-0012), on
/// that day or every day it is planned (ADR-0028 §6), each option saying
/// what a pack does and what a lunch costs.
void main() {
  final rules = <String, FoodRules>{
    LunchFixtures.ayandaId: LunchFixtures.ayandaEntry.foodRules,
  };
  const lwazi = LunchFixtures.lwaziId;
  final grapes = CheckedProduct.of(
    planWeekProduct(
      'Seedless white grapes 500 g',
      id: 'grapes',
      retailer: ProductRetailer.woolworths,
    ),
    {lwazi: LunchFixtures.lwaziEntry.foodRules},
  );
  final bananas = CheckedProduct.of(
    planWeekProduct(
      'Bananas 1kg',
      id: 'bananas',
      cents: 1800,
      ingredients: 'Bananas',
    ),
    rules,
  );
  final search = IdeaSearch(
    idea: LunchIdea.checked(
      id: 'bananas',
      slot: LunchSlot.fruit,
      idea: 'Bananas',
      rulesByChild: rules,
      origin: IdeaOrigin.drafted,
    ),
    status: IdeaSearchStatus.done,
    found: [bananas],
  );

  SwapChoice? chosen;

  Future<void> open(
    WidgetTester tester, {
    required bool everyDay,
    Brightness brightness = Brightness.light,
    double scale = 1,
    String childId = LunchFixtures.ayandaId,
    List<(IdeaSearch, CheckedProduct)>? options,
  }) async {
    chosen = null;
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => chosen = await showPlanWeekSwapSheet(
              context: context,
              title: 'Fruit on Tuesday',
              childId: childId,
              options: options ?? [(search, bananas)],
              current: null,
              boxesPerPackOf: (_) => 6,
              everyDay: everyDay,
            ),
            child: const Text('open'),
          ),
        ),
      ),
      providers: const [],
      brightness: brightness,
      textScale: scale,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('says what a pack does and what a lunch costs', (tester) async {
    await open(tester, everyDay: true);
    expect(
      find.text(
        PlanWeekCopy.swapOption(
          idea: 'Bananas',
          price: const Money(1800),
          boxesPerPack: 6,
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('R3.00 a lunch'), findsOneWidget);
  });

  testWidgets('swaps every day as it opens, and one day once unticked', (
    tester,
  ) async {
    await open(tester, everyDay: true);
    await tester.tap(find.text('Bananas 1kg'));
    await tester.pumpAndSettle();
    expect(chosen, isA<SwapToProduct>());
    expect(chosen!.everyDay, isTrue);

    await open(tester, everyDay: true);
    await tester.tap(find.byKey(const ValueKey('swap-every-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlanWeekCopy.leaveEmpty));
    await tester.pumpAndSettle();
    expect(chosen, isA<SwapToEmpty>());
    expect(chosen!.everyDay, isFalse);
  });

  testWidgets('holds dark at 200% text on a small phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, everyDay: false, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text(PlanWeekCopy.swapEveryDay), findsOneWidget);
  });

  testWidgets('a Woolworths product nothing is known to be in, offered to an '
      'allergic child, says to check the label', (tester) async {
    await open(
      tester,
      everyDay: false,
      childId: lwazi,
      options: [(search, grapes)],
    );
    expect(
      find.text(PlanWeekCopy.labelCheck(ProductRetailer.woolworths)),
      findsOneWidget,
    );
  });

  testWidgets('a product whose contents are known says nothing more', (
    tester,
  ) async {
    await open(tester, everyDay: false);
    expect(
      find.text(PlanWeekCopy.labelCheck(ProductRetailer.woolworths)),
      findsNothing,
    );
  });

  testWidgets('the caution holds dark at 200% text on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(
      tester,
      everyDay: false,
      brightness: Brightness.dark,
      scale: 2,
      childId: lwazi,
      options: [(search, grapes)],
    );
    expect(tester.takeException(), isNull);
    expect(
      find.text(PlanWeekCopy.labelCheck(ProductRetailer.woolworths)),
      findsOneWidget,
    );
  });
}
