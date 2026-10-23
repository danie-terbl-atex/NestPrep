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
import 'package:provider/provider.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// The way into *Plan my week* says which week it will plan (lunch-box
/// ADR-0019): the week the board is on, by the name the week bar gives it —
/// one row in the week's planner (ADR-0022), led by the Checkers logo
/// (ADR-0024).
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
            AsyncData<LunchBoard>(:final value) => PlanWeekEntryCard(
              board: value,
              canEdit: true,
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

  testWidgets('says "Let Twig plan this week", then "Let Twig plan next '
      'week" once the board has moved on, and names Checkers in its body '
      '(design-system ADR-0014)', (tester) async {
    await pump(tester);
    expect(find.text('Let Twig plan this week'), findsOneWidget);
    expect(
      find.text(
        'Lunches for every child from what Checkers sells, within your '
        'budget — you check each step.',
      ),
      findsOneWidget,
    );
    harness.board.goToNextWeek();
    // A real turn for the new window to open (vault lesson on awaiting a
    // stream subscription's cancel in a widget test).
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    harness.lunch.emit();
    await tester.pumpAndSettle();
    expect(find.text('Let Twig plan next week'), findsOneWidget);
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
      '${PlanWeekCopy.entryTitle('this week')}\n${PlanWeekCopy.entryBody(ProductRetailer.checkers)}',
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
    expect(find.text('Let Twig plan this week'), findsOneWidget);
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
}
