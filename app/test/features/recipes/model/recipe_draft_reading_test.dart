import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/data/callable_recipe_drafter.dart';
import 'package:nestprep/features/recipes/data/page_link.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_draft_reading.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/model/recipe_page.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

Map<String, Object?> _reply({Map<String, Object?> recipe = const {}}) => {
  'isRecipe': true,
  'callsLeft': 97,
  'imageUrls': ['https://cdn.example.com/a.jpg', 3],
  'recipe': {
    'name': 'Bobotie',
    'summary': 'Spiced mince.',
    'contexts': ['dinner'],
    'placement': {'dinner': 'main', 'brunch': 'main', 'lunch': 'nonsense'},
    'ingredients': [
      {
        'name': 'Mince',
        'quantity': 500,
        'unit': 'g',
        'note': null,
        'group': 'Base',
      },
      {'name': '  '},
      {'quantity': 2},
    ],
    'steps': ['Bake it.', 7],
    'servings': 6,
    'prepMinutes': 15,
    'cookMinutes': null,
    'notes': 'Better tomorrow.',
    'cutShort': true,
    'origin': 'link',
    'sourceUrl': 'https://example.com/bobotie',
    'sourceName': 'example.com',
    ...recipe,
  },
};

void main() {
  group('the reply', () {
    test('reads into a draft', () {
      final reading = RecipeDraftReading.fromWire(_reply());
      final draft = reading.draft!;
      expect(reading.callsLeft, 97);
      expect(draft.name, 'Bobotie');
      expect(draft.summary, 'Spiced mince.');
      expect(draft.placement, {RecipeContext.dinner: RecipeCourse.main});
      expect(draft.ingredients, const [
        RecipeIngredient(
          name: 'Mince',
          quantity: 500,
          unit: 'g',
          group: 'Base',
        ),
      ]);
      expect(draft.steps, ['Bake it.']);
      expect(draft.servings, 6);
      expect(draft.prepMinutes, 15);
      expect(draft.cookMinutes, isNull);
      expect(draft.notes, 'Better tomorrow.');
      expect(draft.cutShort, isTrue);
      expect(draft.origin, RecipeOrigin.link);
      expect(draft.sourceUrl, 'https://example.com/bobotie');
      expect(draft.sourceName, 'example.com');
      expect(draft.candidateImageUrls, ['https://cdn.example.com/a.jpg']);
    });

    test('with no servings invents none', () {
      final reading = RecipeDraftReading.fromWire(
        _reply(recipe: {'servings': null}),
      );
      expect(reading.draft!.servings, isNull);
    });

    test('that says no recipe has no draft, and still counts', () {
      final reading = RecipeDraftReading.fromWire({
        'isRecipe': false,
        'recipe': null,
        'imageUrls': <String>[],
        'callsLeft': 96,
      });
      expect(reading.draft, isNull);
      expect(reading.callsLeft, 96);
    });

    for (final (why, reply) in <(String, Object?)>[
      ('not a map', 'nope'),
      ('no isRecipe', {'callsLeft': 1}),
      ('no calls left', {'isRecipe': false}),
      ('a recipe missing', {'isRecipe': true, 'callsLeft': 1}),
      (
        'a recipe with no name',
        {
          'isRecipe': true,
          'callsLeft': 1,
          'recipe': {'name': ' '},
        },
      ),
    ]) {
      test('$why is unreadable', () {
        expect(
          () => RecipeDraftReading.fromWire(reply),
          throwsA(
            isA<AiFailure>().having(
              (failure) => failure.problem,
              'problem',
              AiProblem.aiUnreadable,
            ),
          ),
        );
      });
    }
  });

  group('a refusal', () {
    AppFailure mapped(String reason, {String code = 'failed-precondition'}) =>
        failureFromRecipeDraftCallable(
          FirebaseFunctionsException(
            code: code,
            message: reason,
            details: {'reason': reason},
          ),
        );

    test('premium opens on this feature', () {
      expect(
        mapped('premiumRequired'),
        isA<PremiumRequiredFailure>().having(
          (failure) => failure.feature,
          'feature',
          PremiumFeature.ownRecipes,
        ),
      );
    });

    test('every reason in the contract is told apart', () {
      expect(mapped('notSignedIn'), isA<HouseholdFailure>());
      expect(mapped('kidAccount'), isA<HouseholdFailure>());
      expect(mapped('badRequest'), isA<HouseholdFailure>());
      expect(mapped('notAMember'), isA<HouseholdFailure>());
      expect(mapped('mealsNotShared'), isA<OwnRecipeFailure>());
      expect(mapped('householdRecipesOff'), isA<OwnRecipeFailure>());
      expect(mapped('sourceLinkNotPublic'), isA<OwnRecipeFailure>());
      expect(mapped('listPhotoTooLarge'), isA<ListScanFailure>());
      expect(mapped('listPhotoNotSupported'), isA<ListScanFailure>());
      for (final problem in AiProblem.values) {
        expect(
          mapped(problem.name),
          isA<AiFailure>().having((f) => f.problem, 'problem', problem),
        );
      }
    });

    test('with no reason, falls back on its code', () {
      FirebaseFunctionsException of(String code) =>
          FirebaseFunctionsException(code: code, message: code);
      expect(
        failureFromRecipeDraftCallable(of('unauthenticated')),
        isA<HouseholdFailure>(),
      );
      expect(
        failureFromRecipeDraftCallable(of('deadline-exceeded')),
        isA<AiFailure>().having(
          (failure) => failure.problem,
          'problem',
          AiProblem.aiUnavailable,
        ),
      );
      expect(
        failureFromRecipeDraftCallable(of('unavailable')),
        isA<UnavailableFailure>(),
      );
    });
  });

  group('what the phone and the server both write down', () {
    final schemas = File('../functions/src/recipes/draft_recipe_schemas.ts')
        .readAsStringSync();
    final link = File('../functions/src/shared/page_link.ts')
        .readAsStringSync();
    final caller = File('../functions/src/recipes/draft_recipe.ts')
        .readAsStringSync();

    test('the page limits agree', () {
      expect(schemas, contains('MAX_PAGE_CHARS = 60_000'));
      expect(RecipePage.maxChars, 60000);
      expect(schemas, contains('MAX_PAGE_IMAGES = ${RecipePage.maxImages}'));
      expect(
        schemas,
        contains('MAX_JSON_LD_BLOCKS = ${RecipePage.maxJsonLdBlocks}'),
      );
      expect(
        schemas,
        contains('MAX_TITLE_CHARS = ${RecipePage.maxTitleChars}'),
      );
      expect(link, contains('PAGE_LINK_MAX = $pageLinkMax'));
    });

    test('the page\'s shape is the one the schema reads', () {
      final wire = const RecipePage(
        url: 'u',
        title: null,
        jsonLd: [],
        text: 't',
        imageUrls: [],
      ).toWire();
      for (final key in wire.keys) {
        expect(schemas, contains('$key: z.'));
      }
    });

    test('the callable is called what the phone calls it', () {
      expect(caller, contains('export const draftRecipe = onCall'));
      expect(caller, contains("feature: 'recipeImport'"));
    });
  });
}
