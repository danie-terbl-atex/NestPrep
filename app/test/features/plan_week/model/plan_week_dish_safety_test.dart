import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/lunch_week_request.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/ingredient_find.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/shop_week_assembly.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/plan_week_dish_fixture.dart';
import '../../../support/plan_week_packing.dart';

/// A dish goes only to a child for whom every ingredient has a product they
/// may have, and is read on its search words too (lunch-box ADR-0023): the
/// phone applies the server's rule before it sends a dish and when it places
/// one.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;
  final rules = <String, FoodRules>{
    lwazi: LunchFixtures.lwaziEntry.foodRules,
    ayanda: LunchFixtures.ayandaEntry.foodRules,
  };
  final draft = PlanWeekDishFixture.draft;

  IdeaSearch dishFor(List<List<CheckedProduct>> found) => IdeaSearch(
    idea: LunchIdea(
      id: 'idea-1',
      slot: LunchSlot.main,
      idea: 'Wrap',
      searchTerm: 'wraps',
      why: '',
      childIds: const [lwazi, ayanda],
      excluded: const [],
      origin: IdeaOrigin.drafted,
      dish: draft,
    ),
    status: IdeaSearchStatus.done,
    ingredients: [
      for (final (index, products) in found.indexed)
        IngredientFind(ingredient: draft.ingredients[index], found: products),
    ],
  );

  final tortillas = CheckedProduct.of(PlanWeekDishFixture.tortillas, rules);
  final peanutChicken = CheckedProduct.of(
    planWeekProduct(
      'Satay Chicken Strips',
      id: 'satay',
      ingredients: 'Chicken, peanuts',
    ),
    rules,
  );
  final plainChicken = CheckedProduct.of(PlanWeekDishFixture.chicken, rules);

  test(
    'a child an ingredient has no safe product for does not get the dish',
    () {
      final search = dishFor([
        [tortillas],
        [peanutChicken],
      ]);
      expect(search.dishChildIds, [ayanda]);
      expect(search.hasKept, isTrue);
    },
  );

  test('an ingredient the shop had nothing for means no dish at all', () {
    final search = dishFor([
      [tortillas],
      const [],
    ]);
    expect(search.dishChildIds, isEmpty);
    expect(search.hasKept, isFalse);
    final wire = LunchWeekRequest.toWire(
      householdId: 'h1',
      week: LunchFixtures.week,
      childIds: {lwazi, ayanda},
      searches: [search],
      packing: packingFor(const {LunchSlot.main}),
    );
    expect(wire['ideas'], isEmpty);
  });

  test('is sent for the children it can serve, with each ingredient’s search words', () {
    final wire = LunchWeekRequest.toWire(
      householdId: 'h1',
      week: LunchFixtures.week,
      childIds: {lwazi, ayanda},
      searches: [
        dishFor([
          [tortillas],
          [peanutChicken, plainChicken],
        ]),
      ],
      packing: packingFor(const {LunchSlot.main}),
    );
    final idea =
        (wire['ideas']! as List<Object?>).single! as Map<String, Object?>;
    expect(idea['childIds'], [lwazi, ayanda]);
    final lines =
        (idea['dish']! as Map<String, Object?>)['ingredients']!
            as List<Object?>;
    final chicken = lines.last! as Map<String, Object?>;
    expect(chicken['searchTerm'], 'chicken strips');
    expect(
      [
        for (final product in chicken['products']! as List<Object?>)
          (product! as Map<String, Object?>)['productId'],
      ],
      ['chick'],
      reason: 'only products every child of the dish may have',
    );
  });

  test(
    'is never placed for a child it cannot serve, whatever the server says',
    () {
      final search = dishFor([
        [tortillas],
        [peanutChicken],
      ]);
      final plan = ShopWeekAssembly.fromReply(
        board: PlanWeekDishFixture.board(),
        childIds: {lwazi, ayanda},
        searches: [search],
        reply: LunchWeekReply.fromWire({
          'lunches': [
            for (final child in [lwazi, ayanda])
              {
                'childId': child,
                'day': 3,
                'slot': 'main',
                'ideaId': 'idea-1',
                'productId': 'dish:idea-1',
              },
          ],
          'packs': const <Object?>[],
          'dishes': [
            {
              'ideaId': 'idea-1',
              'parts': [
                {'ingredient': 'Wholewheat tortillas', 'productId': 'tort'},
                {'ingredient': 'Chicken strips', 'productId': 'satay'},
              ],
            },
          ],
        }),
        budget: const Money(50000),
        packing: packingFor({LunchSlot.main}),
      );
      expect(
        {for (final child in plan.children) child.childId: child.added.length},
        {lwazi: 0, ayanda: 1},
      );
    },
  );

  test(
    'saving a recipe sends each ingredient’s search words for its codes',
    () {
      final wire = draft.toSaveWire(alsoContains: const {Allergen.soy});
      final lines = wire['ingredients']! as List<Object?>;
      expect(
        (lines.last! as Map<String, Object?>)['searchTerm'],
        'chicken strips',
      );
    },
  );
}
