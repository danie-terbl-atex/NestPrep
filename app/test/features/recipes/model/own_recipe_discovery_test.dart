import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/model/recipe_catalogue.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_discovery.dart';
import 'package:nestprep/features/recipes/model/recipe_facet.dart';
import 'package:nestprep/features/recipes/model/recipe_filter.dart';
import 'package:nestprep/features/recipes/model/recipe_shelf.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/recipe_fixtures.dart';

void main() {
  final today = CalendarDate(2026, 10, 22);
  final own = RecipeFixtures.own();
  final merged = RecipeCatalogue.merged(RecipeFixtures.catalogue, [own]);

  RecipeDiscovery discover([RecipeFilter filter = const RecipeFilter()]) =>
      RecipeDiscovery.of(merged, filter: filter, today: today);

  test('merged, it is one lookup in name order', () {
    expect(merged.byId[own.id], own);
    final names = [
      for (final recipe in merged.recipes) recipe.name.toLowerCase(),
    ];
    expect(names, [...names]..sort());
    expect(
      RecipeCatalogue.merged(RecipeFixtures.catalogue, const []).recipes,
      RecipeFixtures.catalogue,
    );
  });

  test('one own recipe makes a shelf, and that shelf comes first', () {
    final shelves = discover().shelves;
    expect(shelves.first.kind, RecipeShelfKind.ours);
    expect(shelves.first.recipes, [own]);
  });

  test('no own recipes, no shelf', () {
    final catalogue = RecipeCatalogue(RecipeFixtures.catalogue);
    final shelves = RecipeDiscovery.of(
      catalogue,
      filter: const RecipeFilter(),
      today: today,
    ).shelves;
    expect(
      shelves.map((shelf) => shelf.kind),
      isNot(contains(RecipeShelfKind.ours)),
    );
  });

  test('every other shelf still needs two', () {
    final lonely = RecipeFixtures.meal(
      'one-pudding',
      'One pudding',
      placement: const {RecipeContext.dinner: 'dessert'},
    );
    final shelves = RecipeDiscovery.of(
      RecipeCatalogue([lonely]),
      filter: const RecipeFilter(),
      today: today,
    ).shelves;
    expect(shelves, isEmpty);
  });

  test('Tonight never picks an own recipe, on any day', () {
    final onlyOwn = [own, RecipeFixtures.own(id: 'own-ffffffffffffffffffff')];
    for (var offset = 0; offset < 14; offset++) {
      final day = today.addDays(offset);
      expect(RecipeDiscovery.tonightFrom(onlyOwn, day), isNull);
      expect(RecipeDiscovery.tonightFrom(merged.recipes, day)?.isOwn, isFalse);
    }
  });

  test('the Ours chip is offered first, and finds only own recipes', () {
    expect(merged.facets.first, RecipeFacet.ours);
    expect(discover(const RecipeFilter(facet: RecipeFacet.ours)).results, [
      own,
    ]);
    expect(
      RecipeCatalogue(RecipeFixtures.catalogue).facets,
      isNot(contains(RecipeFacet.ours)),
    );
  });

  test('a search and a meal chip find it like any other', () {
    expect(discover(const RecipeFilter(query: 'gran')).results, [own]);
  });
}
