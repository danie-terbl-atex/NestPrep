import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_day_card.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/lunch_board_rig.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';

/// The lunch board reads by scope, narrowest first (lunch-box ADR-0022):
/// the child's rules, the day on show, the whole week with its planner and
/// its days, then the tools — and somebody who may only look gets the
/// day and the week to read, with nothing that changes them.
void main() {
  late LunchPlanningHarness harness;

  tearDown(() => harness.close());

  Future<void> arrive(WidgetTester tester) async {
    harness.lunch.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {
            LunchFixtures.key(1, LunchSlot.main): LunchPick.of(
              LunchFixtures.wrap,
            ),
          },
        ),
      ],
    );
    harness.emitPlanning();
    await tester.pumpAndSettle();
  }

  testWidgets('the child’s rules, then the day, then the week’s planner and '
      'its days, then the tools', (tester) async {
    harness = await LunchBoardRig.pump(tester);
    // Tall enough that every section is built at once.
    tester.view.physicalSize = const Size(420 * 3, 8000 * 3);
    await arrive(tester);
    double top(Finder finder) => tester.getTopLeft(finder.first).dy;

    final rules = top(find.textContaining('school rule'));
    final day = top(find.text(LunchCopy.planThisLunch));
    final goTo = top(find.text(LunchCopy.packFavourite));
    final planner = top(find.text(LunchCopy.planWholeWeek));
    final fillWeek = top(find.text(LunchCopy.fillWeek));
    final firstDay = top(find.byType(LunchDayCard));
    final tools = top(find.text(LunchCopy.toolsTitle));

    expect(rules, lessThan(day));
    expect(day, lessThan(goTo));
    expect(goTo, lessThan(planner));
    expect(planner, lessThan(fillWeek));
    expect(fillWeek, lessThan(firstDay));
    expect(firstDay, lessThan(tools));
    // Filling the week is offered once, in the week's planner.
    expect(find.text(LunchCopy.fillWeek), findsOneWidget);
  });

  testWidgets('fill the week, from the planner, opens the week’s fill and '
      'writes nothing from the board', (tester) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    await bringIntoView(tester, find.text(LunchCopy.fillWeek));
    await tester.tap(find.text(LunchCopy.fillWeek));
    await tester.pumpAndSettle();
    expect(find.text('opened fill-week'), findsOneWidget);
    expect(harness.lunch.repository.writtenPicks, isEmpty);
  });

  testWidgets('somebody who may only look reads the day and the week, and '
      'can change neither', (tester) async {
    harness = await LunchBoardRig.pump(tester, canEdit: false);
    await arrive(tester);
    expect(
      find.text(LunchCopy.dayFor('Today', 'Lwazi').toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(LunchCopy.planWholeWeek), findsNothing);
    expect(find.text(LunchCopy.fillWeek), findsNothing);
    expect(find.text(LunchCopy.packFavourite), findsNothing);
    expect(find.text(LunchCopy.ateIt), findsNothing);
    expect(find.byType(LunchDayCard), findsWidgets);

    // Opening the day shows it, with nothing to pick.
    await tester.tap(find.text('Chicken wrap').first);
    await tester.pumpAndSettle();
    expect(find.text(LunchCopy.suggestedFor('Lwazi')), findsNothing);
  });
}
