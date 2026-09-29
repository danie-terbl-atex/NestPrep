import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_prep.dart';
import 'package:nestprep/features/lunch_box/model/lunch_prep_list.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week_items.dart';

import '../../../support/lunch_fixtures.dart';

/// The read API groceries phase 2 fills its list from, and the Sunday prep
/// list built on it: a household week's boxes summed across every child.
void main() {
  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);
  final plans = [
    LunchFixtures.plan(
      LunchFixtures.lwaziId,
      slots: {
        key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap),
        key(1, LunchSlot.veg): LunchPick.of(LunchFixtures.carrots),
        key(2, LunchSlot.veg): LunchPick.of(LunchFixtures.carrots),
      },
    ),
    LunchFixtures.plan(
      LunchFixtures.ayandaId,
      slots: {
        key(1, LunchSlot.veg): LunchPick.of(LunchFixtures.carrots),
        key(5, LunchSlot.treat): LunchPick.of(LunchFixtures.muffin),
      },
    ),
  ];

  test('gathers the week for every child, one row per item', () {
    final items = LunchWeekItems.from(
      plans: plans,
      library: LunchFixtures.library,
    );
    expect(items.map((item) => item.itemId), ['wrap', 'carrots', 'muffin']);
    final carrots = items.firstWhere((item) => item.itemId == 'carrots');
    expect(carrots.portions, 3);
    expect(carrots.childIds, [LunchFixtures.lwaziId, LunchFixtures.ayandaId]);
    expect(carrots.prepAhead, isTrue);
    expect(carrots.prepNote, 'Cut on Sunday');
  });

  test('names an item as the library does now, else as it was packed', () {
    final renamed = LunchFixtures.carrots.copyWith(name: 'Carrot batons');
    final items = LunchWeekItems.from(plans: plans, library: [renamed]);
    expect(
      items.firstWhere((item) => item.itemId == 'carrots').name,
      'Carrot batons',
    );
    expect(
      items.firstWhere((item) => item.itemId == 'wrap').name,
      'Chicken wrap',
    );
  });

  test('is empty for a week nobody has planned', () {
    expect(
      LunchWeekItems.from(plans: const [], library: LunchFixtures.library),
      isEmpty,
    );
  });

  group('the Sunday prep list', () {
    final items = LunchWeekItems.from(
      plans: plans,
      library: LunchFixtures.library,
    );

    test('puts what can be made ahead first, and the rest after', () {
      final list = LunchPrepList(
        week: LunchFixtures.week,
        items: items,
        prep: LunchPrep.empty(LunchFixtures.week.key),
      );
      expect(list.batch.map((row) => row.item.itemId), ['carrots', 'muffin']);
      expect(list.onHand.map((row) => row.item.itemId), ['wrap']);
      expect(list.totalCount, 3);
      expect(list.doneCount, 0);
    });

    test('remembers what is ready', () {
      final list = LunchPrepList(
        week: LunchFixtures.week,
        items: items,
        prep: LunchPrep(id: LunchFixtures.week.key, done: const ['carrots']),
      );
      expect(list.batch.first.isDone, isTrue);
      expect(list.doneCount, 1);
    });
  });
}
