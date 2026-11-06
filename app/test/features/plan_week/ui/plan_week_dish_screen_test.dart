import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/plan_week_dish_fixture.dart';
import '../../../support/plan_week_rig.dart';
import '../../../support/pump_screen.dart';

/// An AI main on *Plan my week* is a dish (lunch-box ADR-0021): named as
/// one on the ideas list with *How to make it*, searched ingredient by
/// ingredient, shown by its name in the week, and saved — recipe first —
/// when the week is used.
void main() {
  late PlanWeekRig rig;

  setUp(() {
    rig = PlanWeekRig();
    rig.drafter.reply = LunchIdeasReply(
      ideas: [PlanWeekDishFixture.idea],
      budgetCents: 30000,
      callsLeft: 12,
    );
    rig.shop.byQuery['wholewheat tortillas'] = [PlanWeekDishFixture.tortillas];
    rig.shop.byQuery['chicken strips'] = [PlanWeekDishFixture.chicken];
    rig.builder.reply = PlanWeekDishFixture.reply;
  });
  tearDown(() => rig.close());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    Size size = const Size(420, 5000),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      const PlanWeekScreen(),
      providers: [
        ...rig.harness.lunch.providers,
        ...rig.harness.providers,
        ChangeNotifierProvider<PlanWeekController>.value(value: rig.controller),
        planWeekCartsProvider(),
      ],
      brightness: brightness,
      textScale: scale,
    );
    rig.harness.lunch.emit();
    rig.harness.emitPlanning(
      budget: const LunchBudget(id: 'weekly', cents: 30000, updatedBy: 'm'),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('the ideas list names the dish and opens its recipe', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'plan-week-ideas');
    expect(find.text('Mexican wholewheat wrap'), findsOneWidget);
    expect(find.text('Chicken and corn in a soft wrap.'), findsOneWidget);
    expect(
      find.text(PlanWeekCopy.dishMadeWith(2, ProductRetailer.checkers)),
      findsOneWidget,
    );

    await tester.tap(find.text(RecipeCopy.howToMakeShort));
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.draftedNote), findsOneWidget);
    expect(find.text('50 g Chicken strips'), findsOneWidget);
  });

  testWidgets('the dish is searched, placed and saved — recipe first', (
    tester,
  ) async {
    await pump(tester);
    await tapKey(tester, 'plan-week-ideas');
    await tapKey(tester, 'plan-week-search');
    expect(find.text('Mexican wholewheat wrap'), findsWidgets);
    final sent = rig.builder.sent.single.single;
    expect(sent.isDish, isTrue);
    expect(sent.ingredients.map((find) => find.found.length), [1, 1]);

    await rig.controller.use();
    await tester.pumpAndSettle();
    expect(rig.recipeSaver.saved.single.single.draft.name, contains('wrap'));
    expect(
      rig.harness.lunch.repository.seeded.single.single.householdRecipeId,
      'ai-1',
    );
  });

  testWidgets('fits a 360-wide phone in dark at 200% text', (tester) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 5000),
    );
    await tapKey(tester, 'plan-week-ideas');
    expect(tester.takeException(), isNull);
    expect(find.text(RecipeCopy.howToMakeShort), findsOneWidget);
  });
}
