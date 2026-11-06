import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/treat_days_shortcut.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/ui/plan_week_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/plan_week_one_idea.dart';
import '../../../support/plan_week_rig.dart';
import '../../../support/pump_screen.dart';

/// The brief's treat days (lunch-box ADR-0025): shortcuts that light up for
/// the days they stand for, Monday to Friday to fine-tune, hidden while the
/// treat compartment is off — and what was chosen is what the plan is asked
/// for and what the week says.
void main() {
  late PlanWeekRig rig;

  setUp(() => rig = PlanWeekRig()..stockOneIdeaWeek());
  tearDown(() => rig.close());

  final header = find.text(PlanWeekCopy.treatDaysHeader);
  Finder shortcut(TreatDaysShortcut s) =>
      find.byKey(ValueKey('plan-treat-shortcut-${s.name}'));
  Finder day(int weekday) => find.byKey(ValueKey('plan-treat-day-$weekday'));

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

  Future<void> tap(WidgetTester tester, Finder target) async {
    await bringIntoView(tester, target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  bool isLit(WidgetTester tester, Finder chip) =>
      tester.widget<NestChip>(chip).isSelected;

  Set<TreatDaysShortcut> lit(WidgetTester tester) => {
    for (final s in TreatDaysShortcut.values)
      if (isLit(tester, shortcut(s))) s,
  };

  testWidgets('open on Fridays only, and a shortcut or a day changes the '
      'days and which shortcut is lit', (tester) async {
    await pump(tester);
    expect(header, findsOneWidget);
    expect(lit(tester), {TreatDaysShortcut.fridaysOnly});
    expect(isLit(tester, day(DateTime.friday)), isTrue);
    expect(isLit(tester, day(DateTime.monday)), isFalse);

    await tap(tester, shortcut(TreatDaysShortcut.everyDay));
    expect(rig.controller.packing.treatDays, {1, 2, 3, 4, 5});
    expect(lit(tester), {TreatDaysShortcut.everyDay});

    await tap(tester, day(DateTime.wednesday));
    expect(rig.controller.packing.treatDays, {1, 2, 4, 5});
    expect(lit(tester), isEmpty);
    expect(isLit(tester, day(DateTime.wednesday)), isFalse);

    await tap(tester, shortcut(TreatDaysShortcut.none));
    expect(rig.controller.packing.treatDays, isEmpty);
    expect(lit(tester), {TreatDaysShortcut.none});

    await tap(tester, day(DateTime.tuesday));
    expect(rig.controller.packing.treatDays, {DateTime.tuesday});
  });

  testWidgets('hide while the treat compartment is off, and come back with '
      'the days kept', (tester) async {
    await pump(tester);
    await tap(tester, shortcut(TreatDaysShortcut.everyDay));
    await tap(
      tester,
      find.byKey(ValueKey('plan-slot-${LunchSlot.treat.name}')),
    );
    expect(header, findsNothing);
    expect(shortcut(TreatDaysShortcut.none), findsNothing);

    await tap(
      tester,
      find.byKey(ValueKey('plan-slot-${LunchSlot.treat.name}')),
    );
    expect(header, findsOneWidget);
    expect(lit(tester), {TreatDaysShortcut.everyDay});
  });

  testWidgets('what is chosen is asked of the plan and said on the week', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, day(DateTime.monday));
    await tap(tester, find.byKey(const ValueKey('plan-week-ideas')));
    expect(rig.drafter.packed.last.treatDays, {
      DateTime.monday,
      DateTime.friday,
    });
    await tap(tester, find.byKey(const ValueKey('plan-week-search')));
    expect(rig.builder.packed.last.treatDays, {
      DateTime.monday,
      DateTime.friday,
    });
    expect(
      find.text(PlanWeekCopy.treatsOn({DateTime.monday, DateTime.friday})),
      findsOneWidget,
    );
    expect(find.text(PlanWeekCopy.treatsFridaysOnly), findsNothing);
  });

  testWidgets('say nothing about treats on the week when no day has one', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, shortcut(TreatDaysShortcut.none));
    await tap(tester, find.byKey(const ValueKey('plan-week-ideas')));
    await tap(tester, find.byKey(const ValueKey('plan-week-search')));
    expect(find.text(PlanWeekCopy.weekHeadline('this week')), findsOneWidget);
    expect(find.textContaining('Treats go in'), findsNothing);
  });

  testWidgets('hold dark at 200% text on a 360-wide phone', (tester) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    await tap(tester, shortcut(TreatDaysShortcut.everyDay));
    expect(tester.takeException(), isNull);
    await tap(tester, day(DateTime.thursday));
    expect(tester.takeException(), isNull);
    expect(rig.controller.packing.treatDays, {1, 2, 3, 5});
  });
}
