import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_content.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_options.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';

import 'household_fixtures.dart';
import 'lunch_fixtures.dart';

/// A week worth sharing, for the card, the planner and their tests
/// (lunch-box ADR-0005): Lwazi — peanut-allergic, at a nut-free school — has
/// every day packed, a treat on Friday; Ayanda has three days packed.
abstract final class LunchCardFixtures {
  static final library = LunchSeedCatalogue.itemsFor(Fixtures.samMemberId);

  static LunchPick seed(String key) =>
      LunchPick.of(library.firstWhere((item) => item.seedKey == key));

  static Map<String, LunchPick> _day(int day, Map<LunchSlot, String> slots) => {
    for (final MapEntry(key: slot, value: key) in slots.entries)
      LunchPlan.slotKey(day, slot): seed(key),
  };

  static final lwaziWeek = LunchFixtures.plan(
    LunchFixtures.lwaziId,
    slots: {
      ..._day(1, {
        LunchSlot.main: 'cheese-rolls',
        LunchSlot.fruit: 'naartjie',
        LunchSlot.veg: 'carrot-sticks',
        LunchSlot.snack: 'biltong',
      }),
      ..._day(2, {
        LunchSlot.main: 'chicken-mayo',
        LunchSlot.fruit: 'apple',
        LunchSlot.veg: 'cucumber',
        LunchSlot.snack: 'popcorn',
      }),
      ..._day(3, {
        LunchSlot.main: 'pasta-salad',
        LunchSlot.fruit: 'grapes',
        LunchSlot.veg: 'cherry-tomatoes',
        LunchSlot.snack: 'cheese-cubes',
      }),
      ..._day(4, {
        LunchSlot.main: 'mealie-bread',
        LunchSlot.fruit: 'strawberries',
        LunchSlot.veg: 'sugar-snaps',
        LunchSlot.snack: 'rice-cakes',
      }),
      ..._day(5, {
        LunchSlot.main: 'frikkadels',
        LunchSlot.fruit: 'mango',
        LunchSlot.veg: 'baby-corn',
        LunchSlot.snack: 'yoghurt',
        LunchSlot.treat: 'muffin',
      }),
    },
  );

  static final ayandaWeek = LunchFixtures.plan(
    LunchFixtures.ayandaId,
    slots: {
      ..._day(1, {
        LunchSlot.main: 'hummus-pita',
        LunchSlot.fruit: 'banana',
        LunchSlot.snack: 'raisins',
      }),
      ..._day(2, {
        LunchSlot.main: 'egg-mayo',
        LunchSlot.fruit: 'pear',
        LunchSlot.veg: 'pepper-strips',
      }),
      ..._day(5, {
        LunchSlot.main: 'tuna-sandwich',
        LunchSlot.fruit: 'watermelon',
        LunchSlot.veg: 'carrot-sticks',
        LunchSlot.treat: 'jelly',
      }),
    },
  );

  static LunchBoard board({List<LunchPlan>? plans, List<LunchItem>? items}) =>
      LunchBoard.from(
        week: LunchFixtures.week,
        today: LunchFixtures.today,
        roster: LunchFixtures.roster(),
        library: items ?? library,
        favourites: const [],
        plans: plans ?? [lwaziWeek, ayandaWeek],
      );

  static LunchCardContent content(LunchCardOptions options) =>
      LunchCardContent.from(board(), options);
}
