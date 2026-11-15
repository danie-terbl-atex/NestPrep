import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/lunch_board_rig.dart';
import '../../../support/lunch_planning_harness.dart';
import '../../../support/test_flags.dart';

/// The lunch tools, last on the board as one grid of named tiles (lunch-box
/// ADR-0022): each is a way in, behind the switch and grant it had as a
/// button (ADR-0004 to ADR-0008, foundation ADR-0014).
void main() {
  late LunchPlanningHarness harness;

  tearDown(() => harness.close());

  Future<void> arrive(WidgetTester tester) async {
    harness.lunch.emit();
    harness.emitPlanning();
    await tester.pumpAndSettle();
    await bringIntoView(tester, find.text(LunchCopy.toolsTitle));
  }

  Future<void> open(WidgetTester tester, String tile) async {
    await bringIntoView(tester, find.text(tile));
    await tester.tap(find.text(tile));
    await tester.pumpAndSettle();
  }

  testWidgets('with every switch off, only the tools that always were', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester, flags: TestFlags.off);
    await arrive(tester);
    expect(find.text(LunchCopy.openPrep), findsOneWidget);
    expect(find.text(LunchCopy.openLibrary), findsOneWidget);
    expect(find.text(LunchShareCopy.openShare), findsOneWidget);
    expect(find.text(LunchPlanningCopy.openPantry), findsNothing);
    expect(find.text(LunchPlanningCopy.openBudget), findsNothing);
    expect(find.text(LunchPlanningCopy.openKidPicks), findsNothing);
  });

  for (final (tile, place) in [
    (LunchCopy.openLibrary, 'library'),
    (LunchShareCopy.openShare, 'share'),
    (LunchPlanningCopy.openPantry, 'pantry'),
    (LunchPlanningCopy.openKidPicks, 'picks'),
  ]) {
    testWidgets('the $tile tile opens $place', (tester) async {
      harness = await LunchBoardRig.pump(tester);
      await arrive(tester);
      await open(tester, tile);
      expect(find.text('opened $place'), findsOneWidget);
    });
  }

  testWidgets('the Budget tile says what it is and opens budget', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    expect(find.text(LunchPlanningCopy.budgetBody), findsOneWidget);
    await open(tester, LunchPlanningCopy.openBudget);
    expect(find.text('opened budget'), findsOneWidget);
  });

  testWidgets('the Sunday prep tile opens prep', (tester) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    await open(tester, LunchCopy.openPrep);
    expect(find.text('opened prep'), findsOneWidget);
  });

  testWidgets('somebody who may only look gets the tools that only read', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester, canEdit: false);
    await arrive(tester);
    expect(find.text(LunchCopy.openPrep), findsOneWidget);
    expect(find.text(LunchPlanningCopy.openPantry), findsOneWidget);
    expect(find.text(LunchPlanningCopy.openBudget), findsOneWidget);
    expect(find.text(LunchCopy.openLibrary), findsNothing);
    expect(find.text(LunchShareCopy.openShare), findsNothing);
    expect(find.text(LunchPlanningCopy.openKidPicks), findsNothing);
  });
}
