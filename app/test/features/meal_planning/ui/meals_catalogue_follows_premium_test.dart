import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/meals_route.dart';
import 'package:nestprep/app/meals_routes.dart';
import 'package:nestprep/features/lunch_box/data/lunch_repository.dart';
import 'package:nestprep/features/meal_planning/data/meal_repository.dart';
import 'package:nestprep/features/meal_planning/ui/meals_screen.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_source.dart';
import 'package:nestprep/features/recipes/data/recipe_repository.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_lunch_repository.dart';
import '../../../support/fake_meal_repository.dart';
import '../../../support/fake_recipe_photos.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// A catalogue that counts who is listening now, not only who ever asked.
final class _CountingRecipes implements RecipeRepository {
  var opened = 0;
  var listening = 0;

  Stream<List<Recipe>> _watch() {
    opened++;
    late final StreamController<List<Recipe>> controller;
    controller = StreamController<List<Recipe>>(
      onListen: () => listening++,
      onCancel: () => listening--,
    );
    return controller.stream;
  }

  @override
  Stream<List<Recipe>> watchCatalogue() => _watch();

  @override
  Stream<List<Recipe>> watchOwnRecipes(String householdId) =>
      const Stream.empty();

  @override
  Future<List<Recipe>> fetchByIds(Set<String> ids) async => const [];

  @override
  Future<Recipe?> fetchLinked(String householdId, RecipeLink link) async =>
      null;
}

/// The Meals tab's one catalogue listener follows the entitlement
/// (subscriptions ADR-0008): a free household never has one, a Premium one
/// keeps the same one through every rebuild, and a lapse in mid-session ends
/// it.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late _CountingRecipes recipes;
  late FakeMealRepository meals;
  late FakeLunchRepository lunches;

  final premium = Entitlement(
    premiumUntil: DateTime.now().add(const Duration(days: 30)),
  );

  setUp(() {
    recipes = _CountingRecipes();
    meals = FakeMealRepository();
    lunches = FakeLunchRepository();
  });

  tearDown(() async {
    await meals.close();
    await lunches.close();
  });

  Future<SubscriptionHarness> open(
    WidgetTester tester,
    Entitlement entitlement,
  ) async {
    final subscriptions = SubscriptionHarness(entitlement: entitlement);
    final router = GoRouter(
      initialLocation: MealsRoute.pathFor(Fixtures.householdId),
      routes: [mealsRoutes()],
    );
    addTearDown(router.dispose);
    await pumpRouter(
      tester,
      router: router,
      providers: [
        Provider<RecipeRepository>.value(value: recipes),
        Provider<RecipePhotoSource>.value(value: FakeRecipePhotoSource()),
        Provider<MealRepository>.value(value: meals),
        Provider<LunchRepository>.value(value: lunches),
        ...subscriptions.providers,
      ],
    );
    await tester.pump();
    await tester.pump();
    return subscriptions;
  }

  Future<void> becomes(
    WidgetTester tester,
    SubscriptionHarness subscriptions,
    Entitlement entitlement,
  ) async {
    await tester.runAsync(() async {
      subscriptions.entitlements.emit(entitlement);
      await pumpEventQueue();
    });
    await tester.pump();
    await tester.pump();
  }

  RecipeCatalogueController? catalogueOf(WidgetTester tester) => tester
      .element(find.byType(MealsScreen))
      .read<RecipeCatalogueController?>();

  testWidgets('a free household has no catalogue and nothing listens', (
    tester,
  ) async {
    await open(tester, Entitlement.free);

    expect(catalogueOf(tester), isNull);
    expect(recipes.opened, 0);
    expect(recipes.listening, 0);
  });

  testWidgets('a Premium household keeps one catalogue through rebuilds', (
    tester,
  ) async {
    final subscriptions = await open(tester, premium);
    final first = catalogueOf(tester);
    expect(first, isNotNull);
    expect(recipes.listening, 1);

    await becomes(
      tester,
      subscriptions,
      premium.copyWith(
        premiumUntil: DateTime.now().add(const Duration(days: 60)),
      ),
    );

    expect(catalogueOf(tester), same(first));
    expect(recipes.opened, 1);
    expect(recipes.listening, 1);
  });

  testWidgets('a lapse ends the catalogue and its listener; Premium again '
      'starts a new one', (tester) async {
    final subscriptions = await open(tester, premium);
    final first = catalogueOf(tester);
    expect(recipes.listening, 1);

    await becomes(tester, subscriptions, Entitlement.free);

    expect(tester.takeException(), isNull);
    expect(catalogueOf(tester), isNull);
    expect(recipes.listening, 0);
    expect(recipes.opened, 1);

    await becomes(tester, subscriptions, premium);

    expect(catalogueOf(tester), isNot(same(first)));
    expect(catalogueOf(tester), isNotNull);
    expect(recipes.opened, 2);
    expect(recipes.listening, 1);
  });
}
