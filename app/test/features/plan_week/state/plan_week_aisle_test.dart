import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_shelf.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/aisle_shelf.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/state/plan_week_aisle.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/lunch_fixtures.dart';

/// Checkers' lunchbox aisle read before any idea is drafted (lunch-box
/// ADR-0013): a shelf at a time, each product judged for each child, the
/// best kept first, a category when the list is bare, a shelf that cannot
/// be read counted rather than lost, and only the compartments the brief
/// fills.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;
  final rules = <String, FoodRules>{
    lwazi: LunchFixtures.lwaziEntry.foodRules,
    ayanda: LunchFixtures.ayandaEntry.foodRules,
  };
  final near = CheckersArea.capeTown.centre;
  final every = {...LunchSlot.values};

  const yoghurtList = CheckersShelf.productList('69d4ebed9cccb04862bcb67f');
  const yoghurtCategory = CheckersShelf.displayCategory(
    '67075e37ff987811364007b9',
  );
  const biscuitList = CheckersShelf.productList('65bb4f576a79cdbcd449b7b7');
  const vegCategory = CheckersShelf.displayCategory('67075daeff98781136400728');

  late FakeShopCatalogue shop;
  late FakeLunchAisleSource source;
  late PlanWeekAisle aisle;
  late int changes;

  setUp(() {
    shop = FakeShopCatalogue();
    source = FakeLunchAisleSource()
      ..answer = const [
        AisleShelf(
          title: 'Yoghurt snack time',
          slot: LunchSlot.snack,
          list: yoghurtList,
          category: yoghurtCategory,
        ),
        AisleShelf(title: 'Cookies', slot: LunchSlot.treat, list: biscuitList),
        AisleShelf(
          title: 'Baby veg',
          slot: LunchSlot.veg,
          category: vegCategory,
        ),
      ];
    changes = 0;
    aisle = PlanWeekAisle(
      source: source,
      catalogue: shop,
      onChange: () => changes++,
    );
  });

  test('every shelf becomes an answered idea, best kept first', () async {
    shop.byShelf[yoghurtList] = [
      planWeekProduct('Peanut yoghurt', id: 'pyog', ingredients: 'Peanuts'),
      planWeekProduct('Fruit yoghurt', id: 'yog', ingredients: 'Milk'),
    ];
    shop.byShelf[biscuitList] = [
      planWeekProduct('Peanut cookies', id: 'pc', ingredients: 'Peanuts'),
    ];
    shop.byShelf[vegCategory] = [
      planWeekProduct('Baby carrots', id: 'carrots', ingredients: 'Carrots'),
    ];

    await aisle.read(near: near, rulesByChild: rules, slots: every);

    expect(aisle.isReading, isFalse);
    expect(aisle.shelvesRead, 3);
    expect(aisle.unread, 0);
    expect(changes, greaterThan(3));
    final yoghurt = aisle.shelves.first;
    expect(yoghurt.idea.id, 'aisle-1');
    expect(yoghurt.idea.origin, IdeaOrigin.aisle);
    expect(yoghurt.idea.slot, LunchSlot.snack);
    expect(yoghurt.idea.childIds, unorderedEquals([lwazi, ayanda]));
    expect([for (final p in yoghurt.found) p.productId], ['yog', 'pyog']);
    expect(yoghurt.keptFor(lwazi).map((p) => p.productId), ['yog']);
  });

  test('a bare list falls back to its category', () async {
    shop.byShelf[yoghurtCategory] = [
      planWeekProduct('Fruit yoghurt', id: 'yog', ingredients: 'Milk'),
    ];

    await aisle.read(near: near, rulesByChild: rules, slots: every);

    expect(shop.shelves.take(2), [yoghurtList, yoghurtCategory]);
    expect(aisle.shelves.first.kept.single.productId, 'yog');
  });

  test('a shelf that cannot be read is counted, not shown', () async {
    shop.failShelf[biscuitList] = const CheckersFailure(
      CheckersProblem.catalogueUnreachable,
    );

    await aisle.read(near: near, rulesByChild: rules, slots: every);

    expect(aisle.unread, 1);
    expect(
      [for (final s in aisle.shelves) s.idea.idea],
      ['Yoghurt snack time', 'Baby veg'],
    );
  });

  test('a shelf with nothing for anyone is struck out, and the model hears '
      'only kept names, six a shelf', () async {
    shop.byShelf[yoghurtList] = [
      for (var i = 0; i < 9; i++)
        planWeekProduct('Yoghurt $i', id: 'y$i', ingredients: 'Milk'),
    ];
    shop.byShelf[biscuitList] = [
      planWeekProduct('Peanut cookies', id: 'pc', ingredients: 'Peanuts'),
      planWeekProduct('Mystery biscuits', id: 'mb'),
    ];

    await aisle.read(
      near: near,
      rulesByChild: {lwazi: rules[lwazi]!},
      slots: every,
    );

    final cookies = aisle.shelves[1];
    expect(cookies.idea.isStruckOut, isTrue);
    expect(aisle.forModel, hasLength(1));
    expect(aisle.forModel.single.slot, LunchSlot.snack);
    expect(aisle.forModel.single.products, [
      for (var i = 0; i < PlanWeekAisle.namesPerShelf; i++) 'Yoghurt $i',
    ]);
  });

  test(
    'a shelf for a compartment the brief leaves out is never read',
    () async {
      shop.byShelf[yoghurtList] = [
        planWeekProduct('Fruit yoghurt', id: 'yog', ingredients: 'Milk'),
      ];

      await aisle.read(
        near: near,
        rulesByChild: rules,
        slots: {LunchSlot.snack, LunchSlot.veg},
      );

      expect(shop.shelves, isNot(contains(biscuitList)));
      expect(aisle.total, 2);
      expect(
        [for (final s in aisle.shelves) s.idea.slot],
        [LunchSlot.snack, LunchSlot.veg],
      );
    },
  );

  test('clearing drops a read on its way', () async {
    shop.byShelf[yoghurtList] = [
      planWeekProduct('Fruit yoghurt', id: 'yog', ingredients: 'Milk'),
    ];
    final reading = aisle.read(near: near, rulesByChild: rules, slots: every);
    aisle.clear();
    await reading;
    expect(aisle.shelves, isEmpty);
    expect(aisle.isReading, isFalse);
  });
}
