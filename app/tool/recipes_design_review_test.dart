import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meals_view.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meals_screen.dart';
import 'package:nestprep/features/recipes/model/recipe_meal_filter.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/features/recipes/ui/recipe_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_recipe_photos.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/recipe_fixtures.dart';
import '../test/support/recipe_harness.dart';
import 'review_press.dart';

/// The Meals tab's recipes and a recipe's page (design-system ADR-0015,
/// recipes ADR-0003) in the design-review press, light and dark, with one
/// real photo standing in for every recipe's. Regenerate with
///
///     flutter test tool/recipes_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  RecipeHarness harnessFor(WidgetTester tester) {
    final harness = RecipeHarness(photos: FakeRecipePhotoSource.fixture());
    addTearDown(harness.close);
    return harness;
  }

  Future<void> recipes(
    WidgetTester tester,
    String name, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Future<void> Function()? act,
  }) {
    final harness = harnessFor(tester);
    return captureScreen(
      tester,
      name,
      brightness: brightness,
      textScale: textScale,
      screen: MealsScreen(
        view: MealsView.recipes,
        onSelectView: (_) {},
        onSelectTab: (_) {},
        onOpenRecipe: (_) {},
      ),
      providers: harness.providers,
      emit: () async => harness.recipes.emitCatalogue(RecipeFixtures.catalogue),
      act: act,
    );
  }

  Future<void> recipePage(
    WidgetTester tester,
    String name, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Future<void> Function(RecipePageController page)? act,
  }) {
    final harness = harnessFor(tester);
    final page = RecipePageController(
      mealRepository: harness.meals,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      recipeId: RecipeFixtures.bobotie.id,
      familySize: 4,
    );
    return captureScreen(
      tester,
      name,
      brightness: brightness,
      textScale: textScale,
      screen:
          ChangeNotifierProxyProvider<
            RecipeCatalogueController,
            RecipePageController
          >(
            create: (_) => page,
            update: (_, catalogue, page) => page!..followCatalogue(catalogue),
            child: RecipeScreen(onBack: () {}),
          ),
      providers: harness.providers,
      emit: () async => harness.recipes.emitCatalogue(RecipeFixtures.catalogue),
      act: act == null ? null : () => act(page),
    );
  }

  Future<void> scrollBy(WidgetTester tester, double distance) async {
    await tester.drag(screenList(), Offset(0, -distance));
    await tester.pumpAndSettle();
  }

  testWidgets('recipes — light', (tester) => recipes(tester, 'recipes-light'));

  testWidgets(
    'recipes — dark',
    (tester) => recipes(tester, 'recipes-dark', brightness: Brightness.dark),
  );

  testWidgets(
    'recipes, the shelves — light',
    (tester) => recipes(
      tester,
      'recipes-shelves-light',
      act: () => scrollBy(tester, 560),
    ),
  );

  testWidgets(
    'recipes, a search — light',
    (tester) => recipes(
      tester,
      'recipes-filtered-light',
      act: () async {
        await tester.tap(find.text(RecipeCopy.meal(RecipeMealFilter.dinner)));
        await tester.pumpAndSettle();
      },
    ),
  );

  testWidgets(
    'recipes — dark at 200% text',
    (tester) => recipes(
      tester,
      'recipes-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
    ),
  );

  testWidgets(
    'a recipe — light',
    (tester) => recipePage(tester, 'recipe-light'),
  );

  testWidgets(
    'a recipe — dark',
    (tester) => recipePage(tester, 'recipe-dark', brightness: Brightness.dark),
  );

  testWidgets(
    'a recipe, scaled, its ingredients — light',
    (tester) => recipePage(
      tester,
      'recipe-scaled-light',
      act: (page) async {
        page.toggleIngredient(0);
        await scrollBy(tester, 640);
      },
    ),
  );

  testWidgets(
    'a recipe, scaled, its ingredients — dark',
    (tester) => recipePage(
      tester,
      'recipe-scaled-dark',
      brightness: Brightness.dark,
      act: (page) async {
        page.toggleIngredient(0);
        await scrollBy(tester, 640);
      },
    ),
  );

  testWidgets(
    'a recipe, its method — light',
    (tester) => recipePage(
      tester,
      'recipe-method-light',
      act: (page) async {
        page.toggleStep(0);
        await scrollBy(tester, 1350);
      },
    ),
  );

  testWidgets(
    'a recipe — dark at 200% text',
    (tester) => recipePage(
      tester,
      'recipe-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
      act: (_) => scrollBy(tester, 700),
    ),
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'adding a recipe to the week — ${brightness.name}',
      (tester) => recipePage(
        tester,
        'recipe-add-to-week-${brightness.name}',
        brightness: brightness,
        act: (_) async {
          await tester.tap(find.text(RecipeCopy.addToWeek));
          await tester.pumpAndSettle();
        },
      ),
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('this week, with a recipe planned — ${brightness.name}', (
      tester,
    ) async {
      final harness = harnessFor(tester);
      final plan = MealPlanController(
        mealRepository: harness.meals,
        householdClock: harness.clock,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      );
      addTearDown(plan.dispose);
      final bobotie = Meal.named(
        id: Meal.idForRecipe('bobotie'),
        name: 'Bobotie',
        addedBy: Fixtures.samMemberId,
      ).copyWith(recipeId: 'bobotie');
      final braai = Meal.named(
        id: Meal.idForRecipe('boerewors-rolls'),
        name: 'Boerewors rolls',
        addedBy: Fixtures.samMemberId,
      ).copyWith(recipeId: 'boerewors-rolls');
      final oats = Meal.named(
        id: 'oats',
        name: 'Oats with banana',
        addedBy: Fixtures.samMemberId,
      );
      await captureScreen(
        tester,
        'meals-week-recipes-${brightness.name}',
        brightness: brightness,
        screen: MealsScreen(
          view: MealsView.week,
          onSelectView: (_) {},
          onSelectTab: (_) {},
          onOpenRecipe: (_) {},
        ),
        providers: [
          ...harness.providers,
          ChangeNotifierProvider<MealPlanController>.value(value: plan),
        ],
        emit: () async {
          harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
          harness.meals
            ..emitMeals([bobotie, braai, oats])
            ..emitWeek(
              WeekPlan(
                id: plan.weekStart.iso,
                slots: {
                  '4_breakfast': oats.id,
                  '4_dinner': bobotie.id,
                  '5_dinner': braai.id,
                },
              ),
            );
        },
        act: () => scrollBy(tester, 420),
      );
    });
  }
}
