import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/model/recipe_shelf.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_meal_repository.dart';
import '../../../support/fake_recipe_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/recipe_fixtures.dart';

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
      ownRecipesOf: Fixtures.householdId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  final own = RecipeFixtures.own();

  test('asks for this household\'s own recipes', () {
    expect(repository.ownListens, [Fixtures.householdId]);
  });

  test('somebody who cannot read them opens no listener, and waits for '
      'nothing', () async {
    final other = FakeRecipeRepository();
    final catalogue = RecipeCatalogueController(
      recipeRepository: other,
      householdClock: HouseholdClock('Africa/Johannesburg'),
    );
    addTearDown(() async {
      catalogue.dispose();
      await other.close();
    });
    other.emitCatalogue(RecipeFixtures.catalogue);
    await pumpEventQueue();
    expect(other.ownListens, isEmpty);
    expect(catalogue.catalogue, isA<AsyncData<Object?>>());
  });

  test(
    'loading holds until both have arrived, whichever comes first',
    () async {
      repository.emitCatalogue(RecipeFixtures.catalogue);
      await pumpEventQueue();
      expect(controller.catalogue, isA<AsyncLoading<Object?>>());
      expect(controller.discovery, isNull);

      repository.emitOwn([own]);
      await pumpEventQueue();
      expect(controller.catalogue, isA<AsyncData<Object?>>());
      expect(controller.recipe(own.id), own);
      expect(controller.recipe('bobotie')?.isOwn, isFalse);
    },
  );

  test('own recipes arriving first still wait for the catalogue', () async {
    repository.emitOwn([own]);
    await pumpEventQueue();
    expect(controller.catalogue, isA<AsyncLoading<Object?>>());
  });

  test('an own-recipes failure leaves the catalogue standing, and says '
      'why', () async {
    repository.emitCatalogue(RecipeFixtures.catalogue);
    repository.failOwnWith(const PermissionDeniedFailure());
    await pumpEventQueue();

    expect(controller.catalogue, isA<AsyncData<Object?>>());
    expect(controller.recipe('bobotie'), isNotNull);
    expect(controller.ownFailure, isA<PermissionDeniedFailure>());
  });

  test('a catalogue failure is the catalogue\'s, and own recipes keep it from '
      'nothing', () async {
    repository.emitOwn([own]);
    repository.failCatalogueWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.catalogue, isA<AsyncFailure<Object?>>());
    expect(controller.ownFailure, isNull);

    repository.emitOwn([]);
    await pumpEventQueue();
    expect(
      controller.catalogue,
      isA<AsyncFailure<Object?>>(),
      reason: 'a later own-recipes answer never hides the failure',
    );
  });

  test('retrying own recipes listens again and clears the failure', () async {
    repository.emitCatalogue(RecipeFixtures.catalogue);
    repository.failOwnWith(const UnavailableFailure());
    await pumpEventQueue();

    await controller.retryOwnRecipes();
    expect(controller.ownFailure, isNull);
    expect(repository.ownListens, hasLength(2));
    repository.emitOwn([own]);
    await pumpEventQueue();
    expect(controller.recipe(own.id), own);
    expect(controller.discovery?.shelves.first.kind, RecipeShelfKind.ours);
  });

  group('the recipe\'s page', () {
    late FakeMealRepository meals;
    late RecipePageController page;

    setUp(() {
      meals = FakeMealRepository();
      page = RecipePageController(
        mealRepository: meals,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
        recipeId: own.id,
        familySize: 4,
      );
    });

    tearDown(() async {
      page.dispose();
      await meals.close();
    });

    test(
      'never says "gone" while its own recipe is still on the way',
      () async {
        repository.emitCatalogue(RecipeFixtures.catalogue);
        await pumpEventQueue();
        page.followCatalogue(controller);
        expect(page.recipe, isA<AsyncLoading<Object?>>());

        repository.emitOwn([own]);
        await pumpEventQueue();
        page.followCatalogue(controller);
        expect(page.recipe, isA<AsyncData<Object?>>());
      },
    );

    test(
      'a failed own-recipes read is a failure with a retry, not "gone"',
      () async {
        repository.emitCatalogue(RecipeFixtures.catalogue);
        repository.failOwnWith(const UnavailableFailure());
        await pumpEventQueue();
        page.followCatalogue(controller);
        expect(page.recipe, isA<AsyncFailure<Object?>>());
      },
    );

    test('a recipe that really has gone says so', () async {
      repository.emitCatalogue(RecipeFixtures.catalogue);
      repository.emitOwn([]);
      await pumpEventQueue();
      page.followCatalogue(controller);
      expect(page.recipe, const TypeMatcher<AsyncData<Object?>>());
      expect((page.recipe as AsyncData).value, isNull);
    });

    test('while it is being deleted the page keeps showing it', () async {
      repository.emitCatalogue(RecipeFixtures.catalogue);
      repository.emitOwn([own]);
      await pumpEventQueue();
      page.followCatalogue(controller);

      page.holdRecipe();
      repository.emitOwn([]);
      await pumpEventQueue();
      page.followCatalogue(controller);
      expect((page.recipe as AsyncData).value, own);

      page.releaseRecipe(controller);
      expect((page.recipe as AsyncData).value, isNull);
    });
  });
}
