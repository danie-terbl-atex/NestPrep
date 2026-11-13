import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/recipes/data/callable_own_recipe_repository.dart';
import 'package:nestprep/features/recipes/data/own_recipe_failure_mapper.dart';
import 'package:nestprep/features/recipes/data/recipe_document.dart';
import 'package:nestprep/features/recipes/data/recipe_repository.dart';
import 'package:nestprep/features/recipes/model/own_recipe_limits.dart';
import 'package:nestprep/features/recipes/model/own_recipe_photo_paths.dart';
import 'package:nestprep/features/recipes/model/own_recipe_save.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';

void main() {
  final refusals = File('../functions/src/recipes/errors.ts')
      .readAsStringSync();
  final schema = File('../functions/src/recipes/own_recipe.ts')
      .readAsStringSync();
  final caller = File('../functions/src/recipes/own_recipe_caller.ts')
      .readAsStringSync();
  final rules = File('../rules/firestore/household/household_recipes.rules')
      .readAsStringSync();
  final words = File('../functions/src/plan_week/idea_recipe.ts')
      .readAsStringSync();

  test('every refusal the server sends has words in the app', () {
    final start = refusals.indexOf('OWN_RECIPE_REFUSALS =');
    final block = refusals.substring(start, refusals.indexOf('} as const'));
    final server = {
      for (final match in RegExp(
        r'^\s+(\w+): \[',
        multiLine: true,
      ).allMatches(block))
        match.group(1)!,
    };
    final app = {for (final problem in OwnRecipeProblem.values) problem.name};
    expect(server, isNotEmpty);
    expect(app.containsAll(server), isTrue, reason: '$server vs $app');
    for (final problem in OwnRecipeProblem.values) {
      expect(OwnRecipeCopy.problem(problem), isNotEmpty);
    }
  });

  test('the limits are the server\'s', () {
    int limit(String name) {
      final match = RegExp('$name: ([0-9_]+),')
          .firstMatch(schema.substring(schema.indexOf('OWN_RECIPE_LIMITS')));
      return int.parse(match!.group(1)!.replaceAll('_', ''));
    }

    expect(OwnRecipeLimits.name, limit('name'));
    expect(OwnRecipeLimits.summary, limit('summary'));
    expect(OwnRecipeLimits.ingredients, limit('ingredients'));
    expect(OwnRecipeLimits.ingredientName, limit('ingredientName'));
    expect(OwnRecipeLimits.ingredientNote, limit('ingredientNote'));
    expect(OwnRecipeLimits.ingredientGroup, limit('ingredientGroup'));
    expect(OwnRecipeLimits.quantity, limit('quantity'));
    expect(OwnRecipeLimits.steps, limit('steps'));
    expect(OwnRecipeLimits.step, limit('step'));
    expect(OwnRecipeLimits.notes, limit('notes'));
    expect(OwnRecipeLimits.servings, limit('servings'));
    expect(OwnRecipeLimits.minutes, limit('minutes'));
    expect(OwnRecipeLimits.sourceName, limit('sourceName'));
    expect(OwnRecipeLimits.credit, limit('credit'));
    expect(OwnRecipeLimits.gallery, limit('gallery'));
    expect(RecipeRepository.ownRecipeLimit, 300);
    expect(
      schema,
      contains('MAX_OWN_RECIPES = ${RecipeRepository.ownRecipeLimit}'),
    );
    expect(
      rules,
      contains('request.query.limit <= ${RecipeRepository.ownRecipeLimit}'),
    );
    expect(rules, contains("source == '${RecipeDocument.ownSource}'"));
  });

  test('the vocabulary, the flag and the paywall agree', () {
    expect(schema, contains("OWN_SOURCE = '${RecipeDocument.ownSource}'"));
    for (final origin in RecipeOrigin.values) {
      expect(schema, contains("'${origin.name}'"));
    }
    for (final unit in IngredientUnit.values) {
      expect(words, contains("'${unit.code}'"));
    }
    expect(
      caller,
      contains("readFlag(store, '${FeatureFlag.householdRecipes.field}')"),
    );
    expect(
      caller,
      contains("premiumRequired('${PremiumFeature.ownRecipes.name}')"),
    );
  });

  test('a photo\'s path is the one the callable builds', () {
    const card = 'households/h/recipePhotos/own-1/abcdefgh-card.jpg';
    expect(OwnRecipePhotoPaths.card('h', 'own-1', 'abcdefgh'), card);
    expect(
      OwnRecipePhotoPaths.hero('h', 'own-1', 'abcdefgh'),
      'households/h/recipePhotos/own-1/abcdefgh-hero.jpg',
    );
    expect(OwnRecipePhotoPaths.photoIdIn(card), 'abcdefgh');
    expect(
      schema,
      contains(r'households/${householdId}/recipePhotos/${recipeId}/'),
    );
    expect(schema, contains(r'${photo.photoId}-card.jpg'));
    expect(schema, contains(r'${photo.photoId}-hero.jpg'));
  });

  test('the wire names every field the schema requires', () {
    final wire = CallableOwnRecipeRepository.wireOf(
      householdId: 'h',
      recipeId: 'own-1',
      recipe: const OwnRecipeSave(
        name: 'Bobotie',
        summary: '',
        notes: null,
        placement: {RecipeContext.dinner: RecipeCourse.main},
        ingredients: [RecipeIngredient(name: 'Eggs', quantity: 2)],
        steps: ['Bake.'],
        servings: 4,
        prepMinutes: 0,
        cookMinutes: 0,
        origin: RecipeOrigin.typed,
        sourceUrl: null,
        sourceName: null,
        alsoContains: {Allergen.soy},
        photo: OwnRecipePhotoRef(photoId: 'abcdefgh'),
        gallery: [],
      ),
    );
    final block = schema.substring(
      schema.indexOf('saveHouseholdRecipeInput = z'),
      schema.indexOf('.refine('),
    );
    final required = {
      for (final match in RegExp(
        r'^    (\w+): ',
        multiLine: true,
      ).allMatches(block))
        match.group(1)!,
    };
    expect(wire.keys.toSet(), required);
    expect(wire['contexts'], ['dinner']);
    expect(wire['placement'], {'dinner': 'main'});
    expect(wire['alsoContains'], ['soy']);
    expect(wire['photo'], {
      'photoId': 'abcdefgh',
      'credit': null,
      'sourceUrl': null,
    });
    expect((wire['ingredients'] as List).single, {
      'name': 'Eggs',
      'quantity': 2,
      'unit': null,
      'note': null,
      'group': null,
    });
  });

  group('a refusal from the callable', () {
    AppFailure mapped(String code, [String? reason]) =>
        failureFromOwnRecipeCallable(
          FirebaseFunctionsException(
            code: code,
            message: 'server words',
            details: reason == null ? null : {'reason': reason},
          ),
        );

    test('premium is the paywall\'s, on this feature', () {
      final failure = mapped('failed-precondition', 'premiumRequired');
      expect(
        failure,
        isA<PremiumRequiredFailure>().having(
          (f) => f.feature,
          'feature',
          PremiumFeature.ownRecipes,
        ),
      );
    });

    test('its own reasons and the household\'s keep their words', () {
      expect(
        mapped('resource-exhausted', 'recipeLimitReached'),
        isA<OwnRecipeFailure>().having(
          (f) => f.problem,
          'problem',
          OwnRecipeProblem.recipeLimitReached,
        ),
      );
      for (final reason in [
        'notSignedIn',
        'kidAccount',
        'badRequest',
        'notAMember',
      ]) {
        expect(
          mapped('permission-denied', reason),
          isA<HouseholdFailure>().having(
            (f) => f.problem.name,
            'reason',
            reason,
          ),
        );
      }
    });

    test('no reason falls back on the code', () {
      expect(mapped('unavailable'), isA<UnavailableFailure>());
      expect(mapped('deadline-exceeded'), isA<UnavailableFailure>());
      expect(mapped('permission-denied'), isA<PermissionDeniedFailure>());
      expect(mapped('internal'), isA<UnknownFailure>());
    });
  });
}
