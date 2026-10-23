import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/recipes/data/recipe_repository.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';
import 'package:nestprep/features/recipes/ui/linked_recipe_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_recipe_repository.dart';
import '../../../support/pump_screen.dart';

/// *How to make it* (lunch-box ADR-0021 §8): the sheet opens at once under
/// the item's name and shows each of its four states in words — the recipe,
/// a recipe that is not there any more, a failure with a retry, and loading.
void main() {
  const link = HouseholdRecipeLink('ai-wrap');

  const wrap = Recipe(
    id: 'ai-wrap',
    name: 'Mexican wholewheat wrap',
    summary: 'Chicken, corn and cheese rolled in a soft wrap.',
    contexts: {RecipeContext.lunchBox},
    placement: {RecipeContext.lunchBox: 'main'},
    allergens: {Allergen.milk, Allergen.wheat},
    dietTags: [],
    ingredients: [
      RecipeIngredient(name: 'Wholewheat tortilla', quantity: 1),
      RecipeIngredient(name: 'Chicken strips', quantity: 50, unit: 'g'),
      RecipeIngredient(name: 'Grated cheddar', quantity: 2, unit: 'tbsp'),
    ],
    steps: ['Warm the tortilla.', 'Fill and roll up tightly.'],
    servings: 1,
    prepMinutes: 10,
    prepAhead: true,
    prepNote: 'Roll the night before and keep it cold.',
    isAiDrafted: true,
  );

  Future<FakeRecipeRepository> open(
    WidgetTester tester, {
    FakeRecipeRepository? recipes,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final repository = recipes ?? FakeRecipeRepository([wrap]);
    await pumpScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showLinkedRecipeSheet(
                context,
                householdId: 'h1',
                link: link,
                title: wrap.name,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      providers: [Provider<RecipeRepository>.value(value: repository)],
      brightness: brightness,
      textScale: textScale,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets(
    'shows the recipe: method, ingredients, what it contains, and that AI drafted it',
    (tester) async {
      final recipes = await open(tester);
      expect(recipes.linked, [link]);
      expect(find.text(wrap.name), findsOneWidget);
      expect(find.textContaining('Contains '), findsOneWidget);
      expect(find.text(RecipeCopy.draftedNote), findsOneWidget);
      expect(find.text('50 g Chicken strips'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Fill and roll up tightly.'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Fill and roll up tightly.'), findsOneWidget);
    },
  );

  testWidgets('holds the sheet open while the recipe loads', (tester) async {
    final recipes = FakeRecipeRepository([wrap])..hold = Completer<void>();
    await pumpScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLinkedRecipeSheet(
              context,
              householdId: 'h1',
              link: link,
              title: wrap.name,
            ),
            child: const Text('open'),
          ),
        ),
      ),
      providers: [Provider<RecipeRepository>.value(value: recipes)],
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(wrap.name), findsOneWidget);
    expect(find.text(RecipeCopy.ingredientsHeader), findsNothing);
    recipes.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.ingredientsHeader), findsOneWidget);
  });

  testWidgets('says so in place when the recipe is not there any more', (
    tester,
  ) async {
    await open(tester, recipes: FakeRecipeRepository());
    expect(find.text(RecipeCopy.missingTitle), findsOneWidget);
    expect(find.text(RecipeCopy.missingMessage), findsOneWidget);
  });

  testWidgets('a failed read says what happened in words and retries', (
    tester,
  ) async {
    final recipes = FakeRecipeRepository([wrap])
      ..failWith = const UnavailableFailure();
    await open(tester, recipes: recipes);
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    recipes.failWith = null;
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.ingredientsHeader), findsOneWidget);
  });

  testWidgets('fits a 360-wide phone in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, brightness: Brightness.dark, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Roll the night before and keep it cold.'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });
}
