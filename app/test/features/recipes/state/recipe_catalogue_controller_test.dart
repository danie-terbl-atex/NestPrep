import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/model/recipe_facet.dart';
import 'package:nestprep/features/recipes/model/recipe_meal_filter.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_recipe_repository.dart';
import '../../../support/recipe_fixtures.dart';

/// The Meals tab's recipes: one listener, and what is asked of it derived
/// once per change (recipes ADR-0003, `FE-12`).
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeRecipeRepository repository;
  late RecipeCatalogueController controller;

  setUp(() {
    repository = FakeRecipeRepository();
    controller = RecipeCatalogueController(
      recipeRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => DateTime.utc(2026, 10, 22, 9),
      ),
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> deliver() async {
    repository.emitCatalogue(RecipeFixtures.catalogue);
    await pumpEventQueue();
  }

  test('loads, then holds the catalogue and what it shows', () async {
    expect(controller.catalogue, isA<AsyncLoading<Object?>>());
    expect(controller.discovery, isNull);
    await deliver();
    expect(controller.discovery?.tonight, isNotNull);
    expect(
      controller.discovery?.results,
      hasLength(RecipeFixtures.catalogue.length),
    );
  });

  test(
    'a search narrows what it shows, and clearing brings the page back',
    () async {
      await deliver();
      controller.search('malva');
      expect(controller.discovery?.results.single.name, 'Malva pudding');
      expect(controller.discovery?.tonight, isNull);
      controller.clearFilter();
      expect(controller.discovery?.tonight, isNotNull);
    },
  );

  test('a meal and a facet narrow together', () async {
    await deliver();
    controller
      ..selectMeal(RecipeMealFilter.dinner)
      ..toggleFacet(RecipeFacet.braai);
    expect(controller.discovery?.results.map((recipe) => recipe.name), [
      'Boerewors rolls',
      'Chakalaka',
      'Sosaties',
    ]);
  });

  test('asking the same thing twice does not tell anybody twice', () async {
    await deliver();
    var told = 0;
    controller
      ..addListener(() => told++)
      ..search('bobotie')
      ..search('bobotie');
    expect(told, 1);
  });

  test('looks one recipe up by id, for its page and a planned meal', () async {
    expect(controller.recipe('bobotie'), isNull);
    await deliver();
    expect(controller.recipe('bobotie'), RecipeFixtures.bobotie);
    expect(controller.recipe('retired'), isNull);
  });

  test('a failed read is a failure with a retry that listens again', () async {
    repository.failCatalogueWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.catalogue, isA<AsyncFailure<Object?>>());

    await controller.retry();
    expect(controller.catalogue, isA<AsyncLoading<Object?>>());
    expect(repository.catalogueListens, 2);
    await deliver();
    expect(controller.catalogue, isA<AsyncData<Object?>>());
  });
}
