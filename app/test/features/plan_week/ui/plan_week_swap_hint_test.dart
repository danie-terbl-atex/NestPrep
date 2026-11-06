import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
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

/// The week Twig built says it can be changed: a hint above the boxes, and
/// every compartment it filled carries a swap mark and is read out as
/// leading to alternatives.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  late PlanWeekRig rig;

  setUp(() {
    rig = PlanWeekRig()..stockOneIdeaWeek();
    rig.shop.byQuery['yoghurt'] = [
      planWeekProduct(
        'Fruit yoghurt 6 x 100g',
        id: 'yog',
        cents: 3600,
        packCount: 6,
        ingredients: 'Milk',
      ),
    ];
  });
  tearDown(() => rig.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 5000) * 3;
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
    );
    rig.harness.lunch.emit();
    rig.harness.emitPlanning(
      budget: const LunchBudget(id: 'weekly', cents: 30000, updatedBy: 'm'),
    );
    await tester.pumpAndSettle();
    for (final key in ['plan-week-ideas', 'plan-week-search']) {
      final target = find.byKey(ValueKey(key));
      await bringIntoView(tester, target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('the week says a box can be changed, and each new compartment '
      'shows it', (tester) async {
    await pump(tester);
    expect(find.text(PlanWeekCopy.tapToSwap), findsOneWidget);
    final pill = find.byKey(const ValueKey('plan-pill-$lwazi-3-snack'));
    expect(
      find.descendant(
        of: pill,
        matching: find.byIcon(LucideIcons.arrowLeftRight),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(pill),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        hint: PlanWeekCopy.swapHint,
        label: tester.getSemantics(pill).label,
      ),
    );
  });
}
