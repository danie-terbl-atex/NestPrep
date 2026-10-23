import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/lunch_board_rig.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';

/// What acts on the day on show, under its card (lunch-box ADR-0022): a
/// go-to box packed into that day (ADR-0003), and today's box marked packed
/// (ADR-0006) — only while today is the day on show.
void main() {
  late LunchPlanningHarness harness;

  tearDown(() => harness.close());

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  final wrapDay = LunchFavourite.of(
    id: 'wrap-day',
    childId: LunchFixtures.lwaziId,
    name: 'Wrap day',
    box: LunchBox({LunchSlot.main: LunchPick.of(LunchFixtures.wrap)}),
    createdBy: Fixtures.samMemberId,
  );

  Future<void> arrive(WidgetTester tester) async {
    harness.lunch.emit(
      plans: [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {key(2, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple)},
        ),
      ],
      favourites: [wrapDay],
    );
    harness.emitPlanning(
      pantry: [
        const LunchPantryEntry(id: 'apple', portions: 2, updatedBy: 'm'),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> showDay(WidgetTester tester, String weekday) async {
    final semantics = tester.ensureSemantics();
    await tester.tap(
      find.bySemanticsLabel(RegExp('^$weekday, ')),
      warnIfMissed: false,
    );
    semantics.dispose();
    await tester.pumpAndSettle();
  }

  testWidgets('today’s box is marked packed, and can be undone', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    await tester.tap(find.text(LunchPantryCopy.markPacked));
    await tester.pumpAndSettle();
    expect(harness.pantryRepository.packedWrites.single.takeFrom, {'apple': 1});
  });

  testWidgets('marking packed is about today, so another day on show does '
      'not offer it', (tester) async {
    harness = await LunchBoardRig.pump(tester);
    await arrive(tester);
    expect(find.text(LunchPantryCopy.markPacked), findsOneWidget);
    await showDay(tester, 'Thursday');
    expect(find.text(LunchPantryCopy.markPacked), findsNothing);
  });

  testWidgets('a go-to box is packed into the day on show', (tester) async {
    harness = await LunchBoardRig.pump(tester, isPremium: true);
    await arrive(tester);
    await showDay(tester, 'Thursday');
    await tester.tap(find.text(LunchCopy.packFavourite));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wrap day'));
    await tester.pumpAndSettle();
    final picks = harness.lunch.repository.writtenPicks.single.picks;
    expect(picks[key(4, LunchSlot.main)]!.itemId, 'wrap');
    expect(picks.keys.every((slot) => slot.startsWith('4')), isTrue);
  });

  testWidgets('somebody who may only look has nothing to do to the day', (
    tester,
  ) async {
    harness = await LunchBoardRig.pump(tester, canEdit: false);
    await arrive(tester);
    expect(find.text(LunchCopy.viewLunch), findsOneWidget);
    expect(find.text(LunchCopy.packFavourite), findsNothing);
    expect(find.text(LunchPantryCopy.markPacked), findsNothing);
  });
}
