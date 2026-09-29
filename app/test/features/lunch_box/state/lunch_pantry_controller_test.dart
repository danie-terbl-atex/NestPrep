import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_source.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item_draft.dart';
import 'package:nestprep/features/lunch_box/model/lunch_packed_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_week.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';

/// The pantry's controller (lunch-box ADR-0006): it follows the board, packs
/// a box once, fills the week from what is there, and sends what is missing
/// to the grocery list — marked as the pantry's, never twice.
void main() {
  late LunchPlanningHarness harness;

  setUp(() => harness = LunchPlanningHarness());
  tearDown(() => harness.close());

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);
  LunchPantryEntry entry(String itemId, int portions) =>
      LunchPantryEntry(id: itemId, portions: portions, updatedBy: 'm-sam');

  Future<void> arrive({
    List<LunchPantryEntry> pantry = const [],
    List<LunchPackedDay> packed = const [],
    Map<String, LunchPick> ayanda = const {},
  }) async {
    harness.lunch.emit(
      plans: [LunchFixtures.plan(LunchFixtures.ayandaId, slots: ayanda)],
    );
    harness.emitPlanning(pantry: pantry, packed: packed);
    await pumpEventQueue();
  }

  test('waits for the board, then holds the pantry against its week', () async {
    expect(harness.pantry.pantry, isA<AsyncLoading<Object?>>());
    await arrive(
      pantry: [entry('apple', 4)],
      ayanda: {key(3, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple)},
    );
    final week = (harness.pantry.pantry as AsyncData<LunchPantryWeek>).value;
    expect(week.availableOf('apple'), 3);
    expect(harness.pantryRepository.watchedWeeks, [LunchFixtures.week.key]);
  });

  test('a failed read is the pantry’s failure, with a retry', () async {
    harness.pantryRepository.failPantryWith(const UnavailableFailure());
    await arrive();
    expect(harness.pantry.pantry, isA<AsyncFailure<Object?>>());
  });

  test('a pack adds five boxes to what is there; used up is zero', () async {
    await arrive(pantry: [entry('apple', 2)]);
    await harness.pantry.addPack('apple');
    await harness.pantry.addPack('grapes');
    await harness.pantry.markUsedUp('apple');
    expect(harness.pantryRepository.portions, [
      (itemId: 'apple', portions: 7),
      (itemId: 'grapes', portions: 5),
      (itemId: 'apple', portions: 0),
    ]);
  });

  test('packing today’s box takes what the pantry has, and says so if it '
      'was packed already', () async {
    await arrive(pantry: [entry('apple', 1)]);
    final box = LunchBox({
      LunchSlot.fruit: LunchPick.of(LunchFixtures.apple),
      LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
    });
    await harness.pantry.markPacked(
      childId: LunchFixtures.ayandaId,
      date: LunchFixtures.today,
      box: box,
    );
    final write = harness.pantryRepository.packedWrites.single;
    expect(write.takeFrom, {'apple': 1});
    expect(write.day.id, '${LunchFixtures.ayandaId}_2026-09-29');

    harness.pantryRepository.failWritesWith = const PermissionDeniedFailure();
    await harness.pantry.markPacked(
      childId: LunchFixtures.ayandaId,
      date: LunchFixtures.today,
      box: box,
    );
    expect(
      (harness.pantry.actionFailure as LunchPlanningFailure?)?.problem,
      LunchPlanningProblem.alreadyPacked,
    );
  });

  test('undo gives back what the record took', () async {
    await arrive(
      pantry: [entry('apple', 3)],
      packed: [
        LunchPackedDay(
          id: '${LunchFixtures.ayandaId}_2026-09-29',
          childId: LunchFixtures.ayandaId,
          date: '2026-09-29',
          week: LunchFixtures.week.key,
          itemIds: const ['apple'],
          by: 'm-sam',
        ),
      ],
    );
    await harness.pantry.unmarkPacked(
      childId: LunchFixtures.ayandaId,
      date: LunchFixtures.today,
    );
    expect(harness.pantryRepository.unpacked.single.giveBack, {'apple': 1});
  });

  test('fill from the pantry packs what is there first', () async {
    await arrive(pantry: [entry('apple', 5)]);
    harness.pantry.setPlanningFromPantry(isOn: true);
    await harness.board.edit.autoFill(
      LunchFixtures.ayandaId,
      bias: harness.pantry.bias,
    );
    final picks = harness.lunch.repository.writtenPicks.single.picks;
    // Ayanda likes grapes, which lead without the pantry; the apples win now.
    expect(picks[key(2, LunchSlot.fruit)]!.itemId, 'apple');
    expect(harness.pantry.bias, isNotNull);
    harness.pantry.setPlanningFromPantry(isOn: false);
    expect(harness.pantry.bias, isNull);
  });

  test(
    'sends the shortfall to groceries once, marked as the pantry’s',
    () async {
      await arrive(
        pantry: [entry('apple', 1)],
        ayanda: {
          key(3, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
          key(4, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
          key(3, LunchSlot.snack): LunchPick.of(LunchFixtures.biltong),
        },
      );
      final sending = harness.pantry.sendShortfallToGroceries(
        quantityFor: (boxes) => 'for $boxes',
      );
      await pumpEventQueue();
      harness.groceries.emitItems([
        const GroceryItem(
          id: 'g1',
          name: 'biltong',
          addedBy: Fixtures.samMemberId,
        ),
      ]);
      expect(await sending, 1);
      expect(harness.groceries.added.single, (
        name: 'Apple slices',
        quantity: 'for 1',
        addedBy: Fixtures.samMemberId,
      ));
      expect(harness.groceries.origins, [GrocerySource.pantry]);
    },
  );

  test('something new is added to the library, then stocked', () async {
    await arrive();
    await harness.pantry.addNewAndStock(
      const LunchItemDraft(
        name: 'Vetkoek',
        slot: LunchSlot.main,
        allergens: {},
      ),
    );
    expect(harness.lunch.repository.addedItems.single.name, 'Vetkoek');
    expect(
      harness.pantryRepository.portions.single.portions,
      LunchPantryEntry.aPack,
    );
  });
}
