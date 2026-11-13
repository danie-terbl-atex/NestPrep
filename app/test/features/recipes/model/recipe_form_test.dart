import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/recipes/model/own_recipe_limits.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_form.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';

import '../../../support/recipe_fixtures.dart';

void main() {
  RecipeForm complete() =>
      const RecipeForm(name: 'Bobotie')
          .withMeal(RecipeContext.dinner, isOn: true)
          .withLine(name: 'Mince')
          .withStep('Bake it.');

  group('what still needs the member', () {
    test('an empty form names everything required', () {
      expect(const RecipeForm().problems, [
        RecipeFormProblem.noName,
        RecipeFormProblem.noMeal,
        RecipeFormProblem.noIngredients,
        RecipeFormProblem.noSteps,
      ]);
    });

    test('a complete form has none', () {
      expect(complete().problems, isEmpty);
    });

    test('the numbers hold the server\'s limits', () {
      for (final bad in ['', '0', '25']) {
        expect(complete().copyWith(servings: bad).problems, [
          RecipeFormProblem.badServings,
        ], reason: 'serves "$bad"');
      }
      expect(complete().copyWith(prepMinutes: '1441').problems, [
        RecipeFormProblem.badPrepMinutes,
      ]);
      expect(complete().copyWith(cookMinutes: '1441').problems, [
        RecipeFormProblem.badCookMinutes,
      ]);
      expect(
        complete().copyWith(prepMinutes: '', cookMinutes: '').problems,
        isEmpty,
      );
    });

    test('a blank name is no name', () {
      expect(complete().copyWith(name: '   ').problems, [
        RecipeFormProblem.noName,
      ]);
    });
  });

  group('rows', () {
    test('a move keeps every row\'s id, and lands where it was dropped', () {
      final form = const RecipeForm()
          .withLine(name: 'a')
          .withLine(name: 'b')
          .withLine(name: 'c');
      final ids = [for (final entry in form.entries) entry.id];
      expect(ids.toSet(), hasLength(3));

      final down = form.withEntryMoved(0, 2);
      expect(down.lines.map((line) => line.name), ['b', 'c', 'a']);
      expect(down.entries.last.id, ids.first);

      final up = form.withEntryMoved(2, 0);
      expect(up.lines.map((line) => line.name), ['c', 'a', 'b']);
    });

    test('method steps move the same way', () {
      final form = const RecipeForm()
          .withStep('one')
          .withStep('two')
          .withStep('three');
      expect(form.withStepMoved(0, 1).steps.map((step) => step.text), [
        'two',
        'one',
        'three',
      ]);
      final removed = form.withoutStep(form.steps[1].id);
      expect(removed.withStep('four').steps.last.id, isNot(form.steps[1].id));
    });

    test('a heading groups the lines under it, and a blank one is nothing', () {
      final form = const RecipeForm()
          .withLine(name: 'Mince')
          .withHeading(' For the custard ')
          .withLine(name: 'Eggs')
          .withHeading('  ')
          .withLine(name: 'Milk');
      expect(form.ingredients.map((line) => line.group), [
        null,
        'For the custard',
        'For the custard',
      ]);
    });

    test('a line\'s unit goes only with an amount', () {
      final form = const RecipeForm().withLine(
        name: 'Salt',
        unit: IngredientUnit.teaspoon,
      );
      expect(form.ingredients.single.unit, isNull);
    });

    test('the caps are the server\'s', () {
      var form = const RecipeForm();
      for (var i = 0; i < OwnRecipeLimits.ingredients; i++) {
        form = form.withLine(name: 'line $i');
      }
      expect(form.canAddLine, isFalse);
      for (var i = 0; i < OwnRecipeLimits.steps; i++) {
        form = form.withStep('step $i');
      }
      expect(form.canAddStep, isFalse);
    });
  });

  group('a meal and its course', () {
    test('a meal comes on as a main, and takes its course with it', () {
      final form = const RecipeForm()
          .withMeal(RecipeContext.lunch, isOn: true)
          .withCourse(RecipeContext.lunch, RecipeCourse.side);
      expect(form.placement, {RecipeContext.lunch: RecipeCourse.side});
      expect(
        form.withMeal(RecipeContext.lunch, isOn: false).placement,
        isEmpty,
      );
    });
  });

  group('allergens', () {
    test('read every word the server reads', () {
      final form =
          const RecipeForm(
                name: 'Peanut bars',
                summary: 'With sesame',
                notes: 'Swap in a little soy',
              )
              .withHeading('For the fish')
              .withLine(name: 'Eggs', note: 'and milk')
              .withStep('Dust with flour.');
      expect(form.derivedAllergens, {
        Allergen.peanut,
        Allergen.sesame,
        Allergen.soy,
        Allergen.fish,
        Allergen.egg,
        Allergen.milk,
        Allergen.wheat,
      });
    });

    test('words it does not know find nothing, which is why a recipe never '
        'gets an all-clear', () {
      final form = const RecipeForm(name: 'Eiers en botter')
          .withLine(name: 'Melk')
          .withStep('Klop die eiers.');
      expect(form.derivedAllergens, isEmpty);
    });

    test('adding one and taking it back touches only what was added', () {
      final form = const RecipeForm().withAllergenToggled(Allergen.soy);
      expect(form.alsoContains, {Allergen.soy});
      expect(form.withAllergenToggled(Allergen.soy).alsoContains, isEmpty);
    });
  });

  group('editing what the server wrote', () {
    test('round-trips, photos and all, cover first', () {
      final recipe = RecipeFixtures.own(
        photo: RecipeFixtures.ownPhoto('abcdefgh'),
        gallery: [RecipeFixtures.ownPhoto('ijklmnop', credit: 'A site')],
        notes: 'Tips',
        alsoContains: const {Allergen.soy},
      );
      final save = RecipeForm.fromRecipe(recipe).toSave();
      expect(save.name, recipe.name);
      expect(save.placement, {RecipeContext.dinner: RecipeCourse.main});
      expect(save.ingredients, recipe.ingredients);
      expect(save.steps, recipe.steps);
      expect(save.servings, recipe.servings);
      expect(save.prepMinutes, recipe.prepMinutes);
      expect(save.cookMinutes, recipe.cookMinutes);
      expect(save.notes, 'Tips');
      expect(save.alsoContains, {Allergen.soy});
      expect(save.photo?.photoId, 'abcdefgh');
      expect(save.gallery.single.photoId, 'ijklmnop');
      expect(save.gallery.single.credit, 'A site');
    });

    test('a making-cover swap keeps every photo', () {
      final form = RecipeForm.fromRecipe(
        RecipeFixtures.own(
          photo: RecipeFixtures.ownPhoto('abcdefgh'),
          gallery: [RecipeFixtures.ownPhoto('ijklmnop')],
        ),
      ).withCover('ijklmnop');
      expect(form.toSave().photo?.photoId, 'ijklmnop');
      expect(form.toSave().gallery.single.photoId, 'abcdefgh');
    });
  });

  group('a draft', () {
    test('fills the form, and clips what the server would refuse', () {
      final draft = RecipeDraft(
        name: 'x' * 100,
        summary: 'y' * 300,
        notes: 'z' * 3000,
        placement: const {
          RecipeContext.lunchBox: RecipeCourse.snack,
          RecipeContext.dinner: RecipeCourse.side,
        },
        ingredients: [
          RecipeIngredient(
            name: 'n' * 100,
            quantity: 50000,
            unit: 'smidgen',
            note: 'o' * 100,
            group: 'g' * 50,
          ),
        ],
        steps: ['s' * 500, '  '],
        servings: 6,
        prepMinutes: 10,
        origin: RecipeOrigin.link,
        sourceUrl: 'https://drizzleanddip.com/bobotie',
        sourceName: 'd' * 100,
      );
      final save = RecipeForm.fromDraft(draft).toSave();
      expect(save.name, hasLength(OwnRecipeLimits.name));
      expect(save.summary, hasLength(OwnRecipeLimits.summary));
      expect(save.notes, hasLength(OwnRecipeLimits.notes));
      expect(save.placement, {RecipeContext.dinner: RecipeCourse.side});
      final line = save.ingredients.single;
      expect(line.name, hasLength(OwnRecipeLimits.ingredientName));
      expect(line.quantity, isNull);
      expect(line.unit, isNull);
      expect(line.note, hasLength(OwnRecipeLimits.ingredientNote));
      expect(line.group, hasLength(OwnRecipeLimits.ingredientGroup));
      expect(save.steps.single, hasLength(OwnRecipeLimits.step));
      expect(save.servings, 6);
      expect(save.origin, RecipeOrigin.link);
      expect(save.sourceUrl, draft.sourceUrl);
      expect(save.sourceName, hasLength(OwnRecipeLimits.sourceName));
    });

    test('says when it was cut short, by the reader or by the limits', () {
      expect(RecipeForm.cutsShort(const RecipeDraft()), isFalse);
      expect(RecipeForm.cutsShort(const RecipeDraft(cutShort: true)), isTrue);
      expect(
        RecipeForm.cutsShort(
          RecipeDraft(
            ingredients: [
              for (var i = 0; i < 31; i++) RecipeIngredient(name: 'line $i'),
            ],
          ),
        ),
        isTrue,
      );
    });
  });
}
