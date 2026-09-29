import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_auto_fill.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pack_counts.dart';
import 'package:nestprep/features/lunch_box/model/lunch_packed_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_bias.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_week.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_suggestions.dart';
import 'package:nestprep/features/lunch_box/model/lunch_taste.dart';

import '../../../support/lunch_fixtures.dart';

/// The pantry held against a week (lunch-box ADR-0006): what the boxes still
/// need, what is left and what is missing — and planning from it, which
/// prefers what is in the house and never promotes the unsafe or disliked.
void main() {
  final library = {for (final item in LunchFixtures.library) item.id: item};
  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  LunchPantryEntry entry(String itemId, int portions) =>
      LunchPantryEntry(id: itemId, portions: portions, updatedBy: 'm-sam');

  LunchPackedDay packedToday(String childId, List<String> itemIds) =>
      LunchPackedDay(
        id: LunchPackedDay.idFor(childId, LunchFixtures.today),
        childId: childId,
        date: LunchFixtures.today.iso,
        week: LunchFixtures.week.key,
        itemIds: itemIds,
        by: 'm-sam',
      );

  // Monday (gone), Tuesday (today), Wednesday: an apple each, for Lwazi.
  final lwaziPlan = LunchFixtures.plan(
    LunchFixtures.lwaziId,
    slots: {
      key(1, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
      key(2, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
      key(3, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
      key(3, LunchSlot.main): LunchPick.of(LunchFixtures.wrap),
    },
  );
  final ayandaPlan = LunchFixtures.plan(
    LunchFixtures.ayandaId,
    slots: {key(4, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple)},
  );

  LunchPantryWeek weekOf({
    List<LunchPantryEntry> entries = const [],
    List<LunchPackedDay> packed = const [],
  }) => LunchPantryWeek.from(
    week: LunchFixtures.week,
    today: LunchFixtures.today,
    entries: entries,
    plans: [lwaziPlan, ayandaPlan],
    packed: packed,
    library: library,
  );

  group('what the week still needs', () {
    test('counts every child’s boxes from today on — not the days gone', () {
      final week = weekOf(entries: [entry('apple', 5)]);
      // Tuesday and Wednesday for Lwazi, Thursday for Ayanda.
      expect(week.lines.single.stillToPack, 3);
      expect(week.availableOf('apple'), 2);
      expect(week.shortfall.map((missing) => missing.item.id), ['wrap']);
    });

    test('a box marked packed today has had its portions already', () {
      final week = weekOf(
        entries: [entry('apple', 5)],
        packed: [
          packedToday(LunchFixtures.lwaziId, ['apple']),
        ],
      );
      expect(week.availableOf('apple'), 3);
      expect(week.isPacked(LunchFixtures.lwaziId, LunchFixtures.today), isTrue);
      expect(
        week.isPacked(LunchFixtures.ayandaId, LunchFixtures.today),
        isFalse,
      );
    });

    test('says what to buy, in boxes, and nothing the pantry covers', () {
      final week = weekOf(entries: [entry('apple', 1), entry('wrap', 1)]);
      expect(
        [
          for (final missing in week.shortfall)
            (missing.item.id, missing.boxes),
        ],
        [('apple', 2)],
      );
      expect(week.boxesShort, 2);
      expect(
        week.lines.firstWhere((line) => line.item.id == 'apple').isShort,
        isTrue,
      );
    });

    test('an entry whose item left the library is not listed', () {
      final week = weekOf(entries: [entry('gone', 3), entry('apple', 5)]);
      expect(week.lines.map((line) => line.item.id), ['apple']);
    });
  });

  group('packing a box', () {
    test('takes one of each thing the pantry holds, never below nothing', () {
      final week = weekOf(entries: [entry('apple', 1), entry('carrots', 0)]);
      final box = LunchBox({
        LunchSlot.fruit: LunchPick.of(LunchFixtures.apple),
        LunchSlot.veg: LunchPick.of(LunchFixtures.carrots),
        LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
      });
      final (counts, taken) = LunchPackCounts.take(box, week);
      expect(counts, {'apple': 1});
      expect(taken, ['apple']);
    });

    test('undoing gives back only to entries still there, with room', () {
      final week = weekOf(entries: [entry('apple', 99), entry('wrap', 2)]);
      final counts = LunchPackCounts.giveBack(
        packedToday(LunchFixtures.lwaziId, ['apple', 'wrap', 'gone']),
        week,
      );
      expect(counts, {'wrap': 1});
    });
  });

  group('planning from what we have', () {
    final rules = LunchFixtures.ayandaEntry.foodRules;
    final taste = LunchTaste.from(
      history: const [],
      current: LunchFixtures.week,
    );

    RankedLunchItems fruit() => LunchSuggestions.rank(
      slot: LunchSlot.fruit,
      library: LunchFixtures.library,
      rules: rules,
      taste: taste,
    );

    test('puts what the pantry has first, and keeps the order within', () {
      // Ayanda likes grapes, so grapes lead the plain ranking.
      expect(fruit().suggested.first.item.id, 'grapes');
      final ordered = LunchPantryBias({'apple': 2}).order(fruit());
      expect(ordered.suggested.map((entry) => entry.item.id), [
        'apple',
        'grapes',
      ]);
    });

    test('never promotes the unsafe or the disliked', () {
      final lwazi = LunchFixtures.lwaziEntry.foodRules;
      final mains = LunchSuggestions.rank(
        slot: LunchSlot.main,
        library: LunchFixtures.library,
        rules: lwazi,
        taste: taste,
      );
      final ordered = LunchPantryBias({'pb': 9}).order(mains);
      expect(ordered.suggested.map((e) => e.item.id), isNot(contains('pb')));
      expect(ordered.unsafe.map((e) => e.item.id), contains('pb'));
    });

    test('fills from the pantry until it runs out, then as it always did', () {
      final result = LunchAutoFill.fill(
        plan: LunchFixtures.plan(LunchFixtures.ayandaId),
        week: LunchFixtures.week,
        favourites: const [],
        library: LunchFixtures.library,
        rules: rules,
        taste: taste,
        bias: LunchPantryBias({'apple': 2}),
      );
      final fruitDays = [
        for (var day = 1; day <= 5; day++)
          result.picks[key(day, LunchSlot.fruit)]!.itemId,
      ];
      // Two apples in the house: Monday and Tuesday take them, and then the
      // liked grapes lead again, exactly as ADR-0003 ranks them.
      expect(fruitDays.take(3), ['apple', 'apple', 'grapes']);
    });

    test('packs a go-to box only when the pantry has all of it', () {
      final favourite = LunchFavourite.of(
        id: 'f1',
        childId: LunchFixtures.ayandaId,
        name: 'Wrap day',
        box: LunchBox({
          LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
          LunchSlot.fruit: LunchPick.of(LunchFixtures.apple),
        }),
        createdBy: 'm-sam',
      );
      LunchAutoFillResult fillWith(Map<String, int> pantry) =>
          LunchAutoFill.fill(
            plan: LunchFixtures.plan(LunchFixtures.ayandaId),
            week: LunchFixtures.week,
            favourites: [favourite],
            library: LunchFixtures.library,
            rules: rules,
            taste: taste,
            bias: LunchPantryBias(pantry),
          );
      expect(fillWith({'wrap': 1}).favouriteDays, isEmpty);
      expect(fillWith({'wrap': 1, 'apple': 1}).favouriteDays, [1]);
    });
  });
}
