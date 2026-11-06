import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/plan_week_one_idea.dart';
import '../../../support/plan_week_rig.dart';
import '../../../support/pump_screen.dart';

/// The week step says why it packs no treat before Friday (lunch-box
/// ADR-0003) — only when treats are part of this plan.
void main() {
  late PlanWeekRig rig;

  setUp(() => rig = PlanWeekRig()..stockOneIdeaWeek());
  tearDown(() => rig.close());

  final explainer = find.text(PlanWeekCopy.treatsFridaysOnly);

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

  Future<void> toWeek(WidgetTester tester) async {
    await tapKey(tester, 'plan-week-ideas');
    await tapKey(tester, 'plan-week-search');
    expect(find.text(PlanWeekCopy.weekHeadline('this week')), findsOneWidget);
  }

  testWidgets('with treats in the plan, the week says they go in on Fridays '
      'only and can be added by hand', (tester) async {
    await pump(tester);
    expect(rig.controller.packing.slots, contains(LunchSlot.treat));
    expect(explainer, findsNothing, reason: 'not on the brief');
    await toWeek(tester);
    expect(explainer, findsOneWidget);
  });

  testWidgets('with the treat compartment unticked, the week says nothing '
      'about treats', (tester) async {
    await pump(tester);
    await tapKey(tester, 'plan-slot-${LunchSlot.treat.name}');
    expect(rig.controller.packing.slots, isNot(contains(LunchSlot.treat)));
    await toWeek(tester);
    expect(explainer, findsNothing);
  });

  testWidgets('the explainer holds dark at 200% text on a 360-wide phone', (
    tester,
  ) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    await tapKey(tester, 'plan-week-ideas');
    await tapKey(tester, 'plan-week-search');
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      explainer,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(explainer, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
