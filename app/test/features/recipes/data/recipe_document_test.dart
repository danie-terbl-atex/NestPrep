import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/recipes/data/recipe_document.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_cuisine.dart';
import 'package:nestprep/features/recipes/model/recipe_difficulty.dart';
import 'package:nestprep/features/recipes/model/recipe_tag.dart';
import 'package:nestprep/shared/firestore/parsed_document.dart';

/// `recipes/{id}` read without a cast (`ENG-09`): what a family relies on —
/// the name, what is in it, how to make it — present and well formed, or the
/// recipe is left out with the field that was wrong; the rest falls back.
void main() {
  Map<String, Object?> fields() => {
    'name': ' Oat muffin ',
    'summary': 'Soft and not too sweet.',
    'source': 'nestprep',
    'contexts': ['lunchBox', 'picnic'],
    'placement': {'lunchBox': 'treat', 'picnic': 'basket'},
    'allergens': ['wheat', 'egg'],
    'dietTags': ['vegetarian'],
    'ingredients': [
      {'name': 'oats', 'quantity': 1.5, 'unit': 'cups', 'note': null},
      {'name': 'egg', 'quantity': 1, 'unit': null, 'note': 'large'},
      {'name': 'salt', 'quantity': null, 'unit': null, 'note': null},
    ],
    'steps': ['Mix.', 'Bake.'],
    'servings': 12.0,
    'prepMinutes': 25,
    'prepAhead': true,
    'prepNote': 'Freeze half.',
    'status': 'published',
    'version': 3,
  };

  Recipe valid(Map<String, Object?> data) =>
      switch (RecipeDocument.parse('r1', data)) {
        ValidDocument(:final value) => value,
        RejectedDocument(:final reason) => fail('rejected: $reason'),
      };

  String rejection(Map<String, Object?> data) =>
      switch (RecipeDocument.parse('r1', data)) {
        ValidDocument() => fail('a broken recipe was read as valid'),
        RejectedDocument(:final reason) => reason,
      };

  test('a published recipe reads whole, for the lunch box treat', () {
    final recipe = valid(fields());
    expect(recipe.id, 'r1');
    expect(recipe.name, 'Oat muffin');
    expect(recipe.allergens, {Allergen.wheat, Allergen.egg});
    expect(recipe.lunchSlot, LunchSlot.treat);
    expect(recipe.servings, 12, reason: 'a whole double is a whole number');
    expect(recipe.ingredients.map((line) => line.quantity), [1.5, 1, null]);
    expect(recipe.ingredients[1].note, 'large');
    expect(recipe.prepAhead, isTrue);
  });

  test('a context this build does not know is ignored, not a failure', () {
    final recipe = valid(fields());
    expect(recipe.contexts, {RecipeContext.lunchBox});
    expect(recipe.placement.keys, [RecipeContext.lunchBox]);
  });

  test('a recipe not placed in the lunch box has no lunch slot', () {
    final recipe = valid({...fields(), 'placement': <String, Object?>{}});
    expect(recipe.lunchSlot, isNull);
  });

  test('missing what a family relies on, it is left out with the field', () {
    expect(rejection({...fields()}..remove('name')), 'name');
    expect(rejection({...fields(), 'name': '   '}), 'name');
    expect(rejection({...fields()}..remove('allergens')), 'allergens');
    expect(rejection({...fields(), 'steps': 'Mix and bake'}), 'steps');
    expect(rejection({...fields(), 'servings': 0}), 'servings');
    expect(rejection({...fields(), 'prepMinutes': 2.5}), 'prepMinutes');
  });

  test('a retired recipe is not read', () {
    expect(rejection({...fields(), 'status': 'retired'}), 'status');
  });

  test('an allergen code this build cannot check rejects the recipe — '
      'never read as safe', () {
    expect(
      rejection({
        ...fields(),
        'allergens': ['wheat', 'lupin'],
      }),
      'allergens',
    );
  });

  test('one ingredient line without a name rejects the whole list', () {
    expect(
      rejection({
        ...fields(),
        'ingredients': [
          {'name': 'oats'},
          {'quantity': 2},
        ],
      }),
      'ingredients',
    );
  });

  test('the estimated energy reads as a whole number, or none', () {
    expect(valid({...fields(), 'kcalPerServing': 420.0}).kcalPerServing, 420);
    expect(valid(fields()).kcalPerServing, isNull);
    expect(valid({...fields(), 'kcalPerServing': 0}).kcalPerServing, isNull);
    expect(
      valid({...fields(), 'kcalPerServing': '420'}).kcalPerServing,
      isNull,
    );
  });

  test('optional words fall back quietly', () {
    final recipe = valid(
      {...fields()}
        ..remove('summary')
        ..remove('dietTags')
        ..remove('prepNote')
        ..remove('prepAhead'),
    );
    expect(recipe.summary, '');
    expect(recipe.dietTags, isEmpty);
    expect(recipe.prepNote, isNull);
    expect(recipe.prepAhead, isFalse);
  });

  test(
    'a household’s own recipe has no status, and says the AI drafted it',
    () {
      final household = {
        ...fields(),
        'source': 'ai',
        'servings': 1,
        'addedBy': 'm-sam',
      }..remove('status');
      final recipe = switch (RecipeDocument.parseHousehold('ai-1', household)) {
        ValidDocument(:final value) => value,
        RejectedDocument(:final reason) => fail('rejected: $reason'),
      };
      expect(recipe.isAiDrafted, isTrue);
      expect(recipe.servings, 1);
      // The catalogue never reads it: it was never published.
      expect(
        RecipeDocument.parse('ai-1', household),
        isA<RejectedDocument<Recipe>>(),
      );
      expect(valid(fields()).isAiDrafted, isFalse);
    },
  );

  test(
    'a household recipe missing what a family relies on is left out too',
    () {
      expect(
        RecipeDocument.parseHousehold('ai-1', {...fields(), 'steps': null}),
        isA<RejectedDocument<Recipe>>(),
      );
    },
  );

  group('what recipes ADR-0003 added', () {
    Map<String, Object?> dinner() => {
      ...fields(),
      'contexts': ['dinner', 'lunch'],
      'placement': {'dinner': 'main', 'lunch': 'side'},
      'about': 'From the Cape.',
      'cuisine': 'southAfrican',
      'tags': ['braai', 'quick', 'sunday'],
      'cookMinutes': 40,
      'difficulty': 'medium',
      'ingredients': [
        {'name': 'Milk', 'quantity': 250, 'unit': 'ml', 'group': 'Topping'},
      ],
      'photo': {
        'card': 'recipes/r1/card-1a2b.jpg',
        'hero': 'recipes/r1/hero-1a2b.jpg',
        'credit': 'A. Cook',
        'licence': 'CC BY-SA 4.0',
        'sourceUrl': 'https://commons.wikimedia.org/wiki/File:x.jpg',
        'generated': false,
      },
    };

    test('a dinner reads its course, tags, times and photo', () {
      final recipe = valid(dinner());
      expect(recipe.courseIn(RecipeContext.dinner), RecipeCourse.main);
      expect(recipe.courseIn(RecipeContext.lunch), RecipeCourse.side);
      expect(recipe.about, 'From the Cape.');
      expect(recipe.cuisine, RecipeCuisine.southAfrican);
      expect(recipe.cookMinutes, 40);
      expect(recipe.totalMinutes, 65);
      expect(recipe.difficulty, RecipeDifficulty.medium);
      expect(recipe.ingredients.single.group, 'Topping');
      expect(recipe.photo?.hero, 'recipes/r1/hero-1a2b.jpg');
      expect(recipe.photo?.credit, 'A. Cook');
      expect(recipe.photo?.isGenerated, isFalse);
    });

    test('a tag this build does not know is skipped, not the recipe', () {
      expect(valid(dinner()).tags, {RecipeTag.braai, RecipeTag.quick});
    });

    test('an older document without any of it still reads, with defaults', () {
      final recipe = valid(fields());
      expect(recipe.about, isNull);
      expect(recipe.tags, isEmpty);
      expect(recipe.cookMinutes, 0);
      expect(recipe.difficulty, isNull);
      expect(recipe.photo, isNull);
      expect(recipe.ingredients.first.group, isNull);
    });

    test('a photo missing one of its two sizes is no photo at all', () {
      final recipe = valid({
        ...dinner(),
        'photo': {'card': 'recipes/r1/card.jpg', 'generated': true},
      });
      expect(recipe.photo, isNull);
    });

    test('an unknown difficulty or cuisine is left unsaid', () {
      final recipe = valid({
        ...dinner(),
        'difficulty': 'heroic',
        'cuisine': 'lunar',
        'cookMinutes': 'ages',
      });
      expect(recipe.difficulty, isNull);
      expect(recipe.cuisine, isNull);
      expect(recipe.cookMinutes, 0);
    });
  });
}
