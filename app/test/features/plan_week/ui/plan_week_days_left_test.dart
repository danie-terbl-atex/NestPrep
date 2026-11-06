import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/ui/retailer_product_image.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/ui/art/lunch_glyph.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/plan_week_one_idea.dart';
import '../../../support/plan_week_rig.dart';
import '../../../support/pump_screen.dart';

/// *Plan my week* on a Tuesday (lunch-box ADR-0019): Monday and Tuesday
/// have gone, so the brief and the week say which days are left and the
/// week shows only those — and a shop product shows the shop's picture of
/// it, on the week and in the swap sheet.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  late PlanWeekRig rig;

  final note = find.text(
    PlanWeekCopy.daysLeft(
      left: ['Wednesday', 'Thursday', 'Friday'],
      gone: ['Monday', 'Tuesday'],
    ),
  );

  setUp(() {
    rig = PlanWeekRig()..stockOneIdeaWeek();
    rig.shop.byQuery['yoghurt'] = [
      planWeekProduct(
        'Fruit yoghurt 6 x 100g',
        id: 'yog',
        cents: 3600,
        packCount: 6,
        ingredients: 'Milk',
        imageId: 'yog-image',
      ),
    ];
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
    await bringIntoView(tester, target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> toWeek(WidgetTester tester) async {
    await tapKey(tester, 'plan-week-ideas');
    await tapKey(tester, 'plan-week-search');
  }

  Finder pillOn(int day, String slot) =>
      find.byKey(ValueKey('plan-pill-$lwazi-$day-$slot'));

  testWidgets('the brief says which days are left before anything is drafted', (
    tester,
  ) async {
    await pump(tester);
    expect(note, findsOneWidget);
  });

  testWidgets('the week shows only the days left, and says why', (
    tester,
  ) async {
    await pump(tester);
    await toWeek(tester);
    expect(note, findsOneWidget);
    for (final day in [1, 2]) {
      expect(pillOn(day, 'snack'), findsNothing);
      expect(pillOn(day, 'main'), findsNothing);
    }
    expect(pillOn(3, 'snack'), findsOneWidget);
    expect(pillOn(4, 'main'), findsOneWidget);
  });

  testWidgets('a shop product shows its picture on the week and in the swap '
      'sheet; an empty compartment keeps its drawing', (tester) async {
    await pump(tester);
    await toWeek(tester);
    expect(
      find.descendant(
        of: pillOn(3, 'snack'),
        matching: find.byType(RetailerProductImage),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: pillOn(4, 'main'), matching: find.byType(LunchGlyph)),
      findsOneWidget,
    );
    await tapKey(tester, 'plan-pill-$lwazi-3-snack');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('swap-idea-1-yog')),
        matching: find.byType(RetailerProductImage),
      ),
      findsOneWidget,
    );
  });

  testWidgets('survives dark at 200% on a 360-wide phone', (tester) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    expect(tester.takeException(), isNull);
    await toWeek(tester);
    expect(tester.takeException(), isNull);
    await bringIntoView(tester, note);
    expect(tester.takeException(), isNull);
  });
}
