import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/add_to_checkers/ui/retailer_logo.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/plan_week/state/lunch_shop_choice.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_entry_card.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// Twig's way in *Plan the week*'s chooser (lunch-box ADR-0033), led by the
/// logo of the shop it plans at (ADR-0024, ADR-0026) — any shop switched on,
/// on a week that has not gone (ADR-0019).
void main() {
  late LunchPlanningHarness harness;

  setUp(() => harness = LunchPlanningHarness());
  tearDown(() => harness.close());

  Future<void> pump(
    WidgetTester tester, {
    double width = 420,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    bool isPremium = true,
    LunchShopChoice? shopChoice,
  }) async {
    tester.view.physicalSize = Size(width, 1200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      Material(
        child: ListenableBuilder(
          listenable: harness.board,
          builder: (context, _) => switch (harness.board.board) {
            AsyncData<LunchBoard>(:final value) => Builder(
              builder: (context) {
                final shop = PlanWeekEntry.shopFor(context, value);
                if (shop == null) return const SizedBox.shrink();
                return PlanWeekEntryCard(
                  shop: shop,
                  isPremium: isPremium,
                  onTap: () {},
                );
              },
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
      providers: [
        ...harness.lunch.providers,
        ...harness.providers,
        if (!isPremium) ...SubscriptionHarness().providers,
        if (shopChoice != null)
          ChangeNotifierProvider<LunchShopChoice>.value(value: shopChoice),
      ],
      brightness: brightness,
      textScale: textScale,
    );
    harness.lunch.emit();
    await tester.pumpAndSettle();
  }

  testWidgets('says "Let Twig plan it" and names Checkers in its body '
      '(design-system ADR-0014)', (tester) async {
    await pump(tester);
    expect(find.text('Let Twig plan it'), findsOneWidget);
    expect(
      find.text(
        'Lunches for every child from what Checkers sells, within your '
        'budget — you check each step.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('is not offered once the board’s week has gone', (tester) async {
    await pump(tester);
    harness.board.goToPreviousWeek();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    harness.lunch.emit();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-week-open')), findsNothing);
  });

  testWidgets(
    'shows the Checkers logo where Twig was, and no Twig: the week comes '
    'from what Checkers sells (lunch-box ADR-0024)',
    (tester) async {
      await pump(tester);
      final row = find.byKey(const ValueKey('plan-week-open'));
      expect(
        find.descendant(
          of: row,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is RetailerLogo &&
                widget.retailer == ProductRetailer.checkers,
          ),
        ),
        findsOneWidget,
      );
      expect(find.byType(NestTwig), findsNothing);
    },
  );

  testWidgets('the logo is decoration: the row is read once, as its own words, with '
      'no second "Checkers", no tooltip and no tap target of its own', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    final row = find.byKey(const ValueKey('plan-week-open'));
    final announced = <String>[];
    bool collect(SemanticsNode node) {
      announced.add(node.label);
      node.visitChildren(collect);
      return true;
    }

    collect(tester.getSemantics(row));
    expect(announced, [
      '${PlanWeekCopy.entryTitle}\n${PlanWeekCopy.entryBody(ProductRetailer.checkers)}',
    ]);
    final logo = find.descendant(of: row, matching: find.byType(RetailerLogo));
    expect(
      find.descendant(of: logo, matching: find.byType(Tooltip)),
      findsNothing,
    );
    expect(
      find.descendant(of: logo, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(tester.getSize(logo), const Size.square(NestSize.logoMedium));
    semantics.dispose();
  });

  testWidgets('the row with its logo and premium tag fits a 360-wide phone in '
      'dark at 200% text', (tester) async {
    await pump(
      tester,
      width: 360,
      brightness: Brightness.dark,
      textScale: 2,
      isPremium: false,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Let Twig plan it'), findsOneWidget);
    expect(find.text(PlanWeekCopy.premiumTag), findsOneWidget);
    expect(
      tester.getSize(find.byType(RetailerLogo)),
      const Size.square(NestSize.logoMedium),
    );
  });

  testWidgets('the logo and the body follow the shop chosen for lunches '
      '(lunch-box ADR-0026)', (tester) async {
    final choice = planWeekShopChoice(Fixtures.householdId)
      ..choose(ProductRetailer.pickNPay);
    addTearDown(choice.dispose);
    await pump(tester, shopChoice: choice);
    final logo = tester.widget<RetailerLogo>(find.byType(RetailerLogo));
    expect(logo.retailer, ProductRetailer.pickNPay);
    expect(
      find.text(PlanWeekCopy.entryBody(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
  });

  testWidgets('Woolworths chosen for lunches leads the row like any shop', (
    tester,
  ) async {
    final choice = planWeekShopChoice(Fixtures.householdId)
      ..choose(ProductRetailer.woolworths);
    addTearDown(choice.dispose);
    await pump(tester, shopChoice: choice);
    final logo = tester.widget<RetailerLogo>(find.byType(RetailerLogo));
    expect(logo.retailer, ProductRetailer.woolworths);
    expect(
      find.text(PlanWeekCopy.entryBody(ProductRetailer.woolworths)),
      findsOneWidget,
    );
  });

  testWidgets('with nothing chosen for lunches, the family’s own shop leads '
      'the row', (tester) async {
    final family = FakeRetailerPreference();
    family.chosen[Fixtures.householdId] = ProductRetailer.pickNPay;
    final choice = planWeekShopChoice(Fixtures.householdId, family: family);
    addTearDown(choice.dispose);
    await pump(tester, shopChoice: choice);
    final logo = tester.widget<RetailerLogo>(find.byType(RetailerLogo));
    expect(logo.retailer, ProductRetailer.pickNPay);
  });

  group('with shops switched off', () {
    Future<void> switchedOff(Set<FeatureFlag> off) async {
      await harness.close();
      harness = LunchPlanningHarness(
        flags: FeatureFlags(
          defaultOn: true,
          stored: {for (final flag in off) flag: false},
        ),
      );
    }

    testWidgets('a chosen shop switched off gives way to the first still on', (
      tester,
    ) async {
      await switchedOff({FeatureFlag.addToCheckers, FeatureFlag.addToPnp});
      final choice = planWeekShopChoice(Fixtures.householdId)
        ..choose(ProductRetailer.pickNPay);
      addTearDown(choice.dispose);
      await pump(tester, shopChoice: choice);
      final logo = tester.widget<RetailerLogo>(find.byType(RetailerLogo));
      expect(logo.retailer, ProductRetailer.woolworths);
    });

    testWidgets('with every shop off there is nothing to plan from, and no '
        'row', (tester) async {
      await switchedOff({
        FeatureFlag.addToCheckers,
        FeatureFlag.addToPnp,
        FeatureFlag.addToWoolworths,
      });
      await pump(tester);
      expect(find.byKey(const ValueKey('plan-week-open')), findsNothing);
    });
  });
}
