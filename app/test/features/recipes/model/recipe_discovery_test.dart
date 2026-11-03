import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/model/recipe_catalogue.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_discovery.dart';
import 'package:nestprep/features/recipes/model/recipe_facet.dart';
import 'package:nestprep/features/recipes/model/recipe_filter.dart';
import 'package:nestprep/features/recipes/model/recipe_meal_filter.dart';
import 'package:nestprep/features/recipes/model/recipe_shelf.dart';
import 'package:nestprep/features/recipes/model/recipe_tag.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/recipe_fixtures.dart';

/// What the recipes show for a catalogue, a question and a day — worked out
/// once, never in a build (`FE-12`, recipes ADR-0003).
void main() {
  final catalogue = RecipeCatalogue(RecipeFixtures.catalogue);
  final today = CalendarDate(2026, 10, 22);

  RecipeDiscovery discover([RecipeFilter filter = const RecipeFilter()]) =>
      RecipeDiscovery.of(catalogue, filter: filter, today: today);

  List<String> names(RecipeDiscovery discovery) => [
    for (final recipe in discovery.results) recipe.name,
  ];

  group('with nothing asked', () {
    final page = discover();

    test('leads with one dinner main for tonight', () {
      expect(page.tonight?.courseIn(RecipeContext.dinner), RecipeCourse.main);
    });

    test('the same pick all day, a different one tomorrow, each in turn', () {
      final tomorrow = RecipeDiscovery.tonightFrom(
        catalogue.recipes,
        today.addDays(1),
      );
      expect(discover().tonight, page.tonight);
      expect(tomorrow, isNot(page.tonight));
      final week = {
        for (var day = 0; day < 4; day++)
          RecipeDiscovery.tonightFrom(catalogue.recipes, today.addDays(day)),
      };
      expect(week, hasLength(4), reason: 'four dinner mains, four days');
    });

    test('offers the shelves that have at least two on them', () {
      expect(
        [for (final shelf in page.shelves) shelf.kind],
        [
          RecipeShelfKind.sundayClassics,
          RecipeShelfKind.braaiDay,
          RecipeShelfKind.somethingSweet,
        ],
      );
      final braai = page.shelves[1].recipes.map((recipe) => recipe.name);
      expect(braai, containsAll(['Boerewors rolls', 'Sosaties']));
    });

    test('and then every recipe, in name order', () {
      expect(names(page), [
        for (final recipe in RecipeFixtures.catalogue) recipe.name,
      ]);
    });
  });

  group('once something is asked', () {
    test('a meal shows only what is offered for it', () {
      final breakfast = discover(
        const RecipeFilter(meal: RecipeMealFilter.breakfast),
      );
      expect(names(breakfast), ['Mabele porridge']);
      expect(breakfast.tonight, isNull, reason: 'the editorial page gives way');
      expect(breakfast.shelves, isEmpty);
    });

    test('sides and desserts are courses of any meal', () {
      expect(
        names(discover(const RecipeFilter(meal: RecipeMealFilter.sides))),
        ['Chakalaka'],
      );
      expect(
        names(discover(const RecipeFilter(meal: RecipeMealFilter.desserts))),
        ['Malva pudding', 'Melktert'],
      );
    });

    test('the lunch box has its own chip', () {
      expect(
        names(discover(const RecipeFilter(meal: RecipeMealFilter.lunchBox))),
        ['Chicken mayo wrap'],
      );
    });

    test('vegetarian finds vegan dishes too', () {
      expect(
        names(discover(const RecipeFilter(facet: RecipeFacet.vegetarian))),
        ['Chakalaka', 'Mabele porridge'],
      );
    });

    test('a meal and a kind of dish narrow together', () {
      expect(
        names(
          discover(
            const RecipeFilter(
              meal: RecipeMealFilter.dinner,
              facet: RecipeFacet.braai,
            ),
          ),
        ),
        ['Boerewors rolls', 'Chakalaka', 'Sosaties'],
      );
    });

    test('search reads names, summaries and ingredients, any case', () {
      expect(names(discover(const RecipeFilter(query: 'BOBOTIE'))), [
        'Bobotie',
      ]);
      expect(names(discover(const RecipeFilter(query: 'apricot'))), [
        'Malva pudding',
        'Sosaties',
      ]);
      expect(names(discover(const RecipeFilter(query: 'bay leaves'))), [
        'Bobotie',
      ], reason: 'an ingredient, two words, both must be there');
    });

    test('nothing matching is an empty list, not an error', () {
      expect(discover(const RecipeFilter(query: 'sushi')).results, isEmpty);
    });

    test('a second tap on a facet clears it', () {
      const braai = RecipeFilter(facet: RecipeFacet.braai);
      expect(braai.toggling(RecipeFacet.braai).facet, isNull);
      expect(braai.toggling(RecipeFacet.quick).facet, RecipeFacet.quick);
    });
  });

  test('only the chips that would find something are offered', () {
    expect(catalogue.meals, contains(RecipeMealFilter.all));
    expect(catalogue.meals, contains(RecipeMealFilter.lunchBox));
    expect(catalogue.facets, isNot(contains(RecipeFacet.potjie)));
    expect(
      catalogue.facets.first,
      RecipeFacet.braai,
      reason: 'in the order a family reaches for them',
    );
  });

  group('healthy and the ways a family eats (recipes ADR-0006)', () {
    final salmon = RecipeFixtures.meal(
      'salmon-traybake',
      'Salmon traybake',
      placement: const {RecipeContext.dinner: 'main'},
      tags: const {RecipeTag.healthy, RecipeTag.quick},
      dietTags: const ['pescatarian', 'glutenFree', 'banting', 'keto'],
    );
    final stirFry = RecipeFixtures.meal(
      'chicken-stir-fry',
      'Chicken stir-fry',
      placement: const {RecipeContext.dinner: 'main'},
      tags: const {RecipeTag.healthy},
      dietTags: const ['dairyFree'],
    );
    final salad = RecipeFixtures.meal(
      'lentil-salad',
      'Lentil salad',
      placement: const {
        RecipeContext.lunch: 'main',
        RecipeContext.dinner: 'side',
      },
      tags: const {RecipeTag.healthy},
      dietTags: const ['vegetarian', 'vegan', 'glutenFree', 'dairyFree'],
    );
    final healthy = RecipeCatalogue(
      [...RecipeFixtures.catalogue, salmon, stirFry, salad]
        ..sort((a, b) => a.name.compareTo(b.name)),
    );

    RecipeDiscovery among([RecipeFilter filter = const RecipeFilter()]) =>
        RecipeDiscovery.of(healthy, filter: filter, today: today);

    test('the page opens on a shelf of healthy dinner mains', () {
      final shelf = among().shelves.first;
      expect(shelf.kind, RecipeShelfKind.healthyWeeknights);
      expect(shelf.recipes, [stirFry, salmon], reason: 'a healthy side is not');
    });

    test('a diet chip finds what is tagged with it', () {
      expect(names(among(const RecipeFilter(facet: RecipeFacet.banting))), [
        'Salmon traybake',
      ]);
      expect(names(among(const RecipeFilter(facet: RecipeFacet.glutenFree))), [
        'Lentil salad',
        'Salmon traybake',
      ]);
      expect(names(among(const RecipeFilter(facet: RecipeFacet.healthy))), [
        'Chicken stir-fry',
        'Lentil salad',
        'Salmon traybake',
      ]);
    });

    test('a diet chip is offered only once something carries it', () {
      expect(
        healthy.facets,
        containsAll([RecipeFacet.keto, RecipeFacet.dairyFree]),
      );
      expect(catalogue.facets, isNot(contains(RecipeFacet.keto)));
      expect(catalogue.facets, isNot(contains(RecipeFacet.healthy)));
    });
  });

  test('with no dinner main at all there is no pick for tonight', () {
    expect(RecipeDiscovery.tonightFrom([RecipeFixtures.malva], today), isNull);
  });
}
