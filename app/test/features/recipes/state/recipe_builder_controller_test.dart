import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_picker.dart';
import 'package:nestprep/features/recipes/model/own_recipe_limits.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_form.dart';
import 'package:nestprep/features/recipes/state/recipe_builder_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_photo_intake.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_meal_repository.dart';
import '../../../support/fake_own_recipes.dart';
import '../../../support/fake_recipe_photos.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/recipe_fixtures.dart';

void main() {
  late FakeOwnRecipeRepository recipes;
  late FakeOwnRecipePhotoStore store;
  late FakeRecipePhotoPicker picker;
  late FakeRecipePhotoSource photos;
  late FakeMealRepository meals;

  setUp(() {
    recipes = FakeOwnRecipeRepository();
    store = FakeOwnRecipePhotoStore();
    picker = FakeRecipePhotoPicker();
    photos = FakeRecipePhotoSource();
    meals = FakeMealRepository();
  });

  tearDown(() => meals.close());

  RecipeBuilderController builder({
    Recipe? editing,
    RecipeDraft? draft,
    int familySize = 4,
    RecipePhotoIntake? intake,
  }) {
    final controller = RecipeBuilderController(
      ownRecipes: recipes,
      photoStore: store,
      photoPicker: picker,
      photoIntake:
          intake ??
          const RecipePhotoIntake(
            heroCompressor: FakeRecipePhotoCompressor(),
            cardCompressor: FakeRecipePhotoCompressor(),
          ),
      photoSource: photos,
      mealRepository: meals,
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
      familySize: familySize,
      editing: editing,
      draft: draft,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  void fill(RecipeBuilderController controller) => controller.update(
    (form) => form
        .copyWith(name: 'Bobotie')
        .withMeal(RecipeContext.dinner, isOn: true)
        .withLine(name: 'Mince')
        .withStep('Bake it.'),
  );

  final aPhoto = Uint8List.fromList([1, 2, 3]);

  Future<RecipeBuilderController> withOnePhoto() async {
    final controller = builder();
    fill(controller);
    await controller.addPhotoBytes(aPhoto);
    return controller;
  }

  test('a new recipe gets one id in the server\'s shape, for the whole '
      'builder', () {
    expect(builder().recipeId, matches(RegExp(r'^own-[0-9a-f]{20}$')));
    expect(builder().recipeId, isNot(builder().recipeId));
  });

  test('a photo id is one the rules and the callable accept', () async {
    final controller = await withOnePhoto();
    expect(
      controller.form.photos.single.photoId,
      matches(RegExp(r'^[A-Za-z0-9_-]{8,64}$')),
    );
  });

  group('problems', () {
    test('show only once somebody has tried to save', () async {
      final controller = builder();
      expect(controller.shownProblems, isEmpty);
      expect(await controller.save(), isFalse);
      expect(controller.shownProblems, contains(RecipeFormProblem.noName));
      expect(recipes.saves, isEmpty);

      fill(controller);
      expect(controller.shownProblems, isEmpty);
    });
  });

  group('derived allergens', () {
    test('move with the words as they are typed', () {
      final controller = builder();
      expect(controller.derivedAllergens, isEmpty);
      controller.update((form) => form.withLine(name: 'Eggs'));
      expect(controller.derivedAllergens.map((a) => a.name), ['egg']);
    });
  });

  group('saving', () {
    test('uploads card and hero, then calls with the photo\'s id', () async {
      final controller = await withOnePhoto();
      expect(await controller.save(), isTrue);

      final photoId = controller.form.photos.single.photoId;
      final folder =
          'households/${Fixtures.householdId}/recipePhotos/${controller.recipeId}';
      expect(store.uploaded, [
        '$folder/$photoId-card.jpg',
        '$folder/$photoId-hero.jpg',
      ]);
      expect(store.uploaderUids, {Fixtures.samUid});
      final saved = recipes.saves.single;
      expect(saved.recipeId, controller.recipeId);
      expect(saved.recipe.photo?.photoId, photoId);
      expect(controller.isDirty, isFalse);
    });

    test('can\'t be pressed twice', () async {
      final controller = builder();
      fill(controller);
      recipes.hold = Completer<void>();
      final first = controller.save();
      await pumpEventQueue();
      expect(controller.isSaving, isTrue);
      expect(await controller.save(), isFalse);
      recipes.hold!.complete();
      expect(await first, isTrue);
      expect(recipes.saves, hasLength(1));
    });

    test('a refusal tidies up what this attempt uploaded', () async {
      final controller = await withOnePhoto();
      recipes.failWith = const OwnRecipeFailure(
        OwnRecipeProblem.recipeLimitReached,
      );
      expect(await controller.save(), isFalse);
      expect(store.removed, store.uploaded);
      expect(store.stored, isEmpty);
      expect(controller.actionFailure, isA<OwnRecipeFailure>());
      expect(controller.isDirty, isTrue);
    });

    test('a retry keeps the same id and uploads afresh', () async {
      final controller = await withOnePhoto();
      recipes.failWith = const UnknownFailure('refused');
      expect(await controller.save(), isFalse);
      recipes.failWith = null;
      expect(await controller.save(), isTrue);
      expect(recipes.saves, hasLength(2));
      expect(recipes.saves[0].recipeId, recipes.saves[1].recipeId);
      expect(store.stored, hasLength(2));
    });

    test('no answer leaves the photos, because the call may have landed; the '
        'retry skips them', () async {
      final controller = await withOnePhoto();
      recipes.failWith = const UnavailableFailure();
      expect(await controller.save(), isFalse);
      expect(store.removed, isEmpty);

      recipes.failWith = null;
      expect(
        await controller.save(),
        isTrue,
        reason: 'Storage refuses a second upload to the same path',
      );
      expect(store.uploaded, hasLength(2));
      expect(recipes.saves[0].recipeId, recipes.saves[1].recipeId);
    });

    test('a tidy-up that failed is not re-uploaded on the retry', () async {
      final controller = await withOnePhoto();
      recipes.failWith = const UnknownFailure('refused');
      store.failRemoveWith = const UnavailableFailure();
      expect(await controller.save(), isFalse);
      expect(store.stored, hasLength(2));

      recipes.failWith = null;
      store.failRemoveWith = null;
      expect(await controller.save(), isTrue);
    });

    test('a failed upload tidies up the half it stored', () async {
      final controller = await withOnePhoto();
      store.stored.add(
        'households/${Fixtures.householdId}/recipePhotos/${controller.recipeId}/'
        '${controller.form.photos.single.photoId}-hero.jpg',
      );
      expect(await controller.save(), isFalse);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      expect(store.removed, hasLength(1));
      expect(recipes.saves, isEmpty);
    });
  });

  group('editing', () {
    final recipe = RecipeFixtures.own(
      photo: RecipeFixtures.ownPhoto('abcdefgh'),
      gallery: [RecipeFixtures.ownPhoto('ijklmnop')],
    );

    test('keeps the recipe\'s id and uploads only what is new', () async {
      final controller = builder(editing: recipe);
      expect(controller.recipeId, recipe.id);
      expect(controller.isDirty, isFalse);
      expect(controller.isEditing, isTrue);

      expect(await controller.save(), isTrue);
      expect(store.uploaded, isEmpty);
      expect(recipes.saves.single.recipe.photo?.photoId, 'abcdefgh');
    });

    test('re-runs the planned meal\'s lines, at the family\'s size', () async {
      meals.plannedOwnRecipes.add(recipe.id);
      final controller = builder(editing: recipe, familySize: 8);
      controller.update(
        (form) => form.withEntryChanged(
          RecipeFormLine(
            id: form.lines.first.id,
            name: 'Lamb mince',
            amount: 500,
          ),
        ),
      );
      expect(await controller.save(), isTrue);

      final write = meals.ingredientWrites.single;
      expect(write.mealId, Meal.idForRecipe(recipe.id));
      expect(write.ingredients.first.name, 'Lamb mince');
      expect(write.ingredients.first.amount, 1000);
      expect(controller.missedMealLines, isFalse);
    });

    test('an unplanned recipe writes no meal', () async {
      final controller = builder(editing: recipe);
      expect(await controller.save(), isTrue);
      expect(meals.ingredientWrites, isEmpty);
    });

    test('a new recipe has no meal to write', () async {
      final controller = builder();
      fill(controller);
      meals.plannedOwnRecipes.add(controller.recipeId);
      expect(await controller.save(), isTrue);
      expect(meals.ingredientWrites, isEmpty);
    });

    test('a meal that can\'t be rewritten still saves, and says so', () async {
      meals.plannedOwnRecipes.add(recipe.id);
      meals.failWritesWith = const UnavailableFailure();
      final controller = builder(editing: recipe);
      expect(await controller.save(), isTrue);
      expect(controller.missedMealLines, isTrue);
    });

    test(
      'a removed photo is forgotten only once the save has landed',
      () async {
        final controller = builder(editing: recipe);
        controller.update((form) => form.withoutPhoto('ijklmnop'));
        recipes.failWith = const UnknownFailure('refused');
        expect(await controller.save(), isFalse);
        expect(photos.forgotten, isEmpty);

        recipes.failWith = null;
        expect(await controller.save(), isTrue);
        expect(photos.forgotten, [
          RecipeFixtures.ownPhoto('ijklmnop').card,
          RecipeFixtures.ownPhoto('ijklmnop').hero,
        ]);
      },
    );
  });

  group('a draft', () {
    test('opens filled, with something to lose, and keeps its images for '
        'whoever fetches them', () {
      final controller = builder(
        draft: const RecipeDraft(
          name: 'Malva',
          candidateImageUrls: ['https://example.com/a.jpg'],
          cutShort: true,
        ),
      );
      expect(controller.form.name, 'Malva');
      expect(controller.isDirty, isTrue);
      expect(controller.isCutShort, isTrue);
      expect(controller.candidateImageUrls, ['https://example.com/a.jpg']);
    });
  });

  group('photos', () {
    test('asks for no more than are left, and takes many', () async {
      final controller = builder();
      picker.picks = [aPhoto, aPhoto];
      await controller.addPhotos(RecipePhotoOrigin.library);
      expect(picker.limits, [OwnRecipeLimits.photos]);
      expect(controller.form.photos, hasLength(2));

      await controller.addPhotos(RecipePhotoOrigin.library);
      expect(picker.limits.last, OwnRecipeLimits.photos - 2);
    });

    test('backing out changes nothing', () async {
      final controller = builder();
      await controller.addPhotos(RecipePhotoOrigin.camera);
      expect(controller.form.photos, isEmpty);
      expect(controller.isDirty, isFalse);
      expect(controller.actionFailure, isNull);
    });

    test('a picture that can\'t be read says so, and keeps the rest', () async {
      final controller = builder(
        intake: const RecipePhotoIntake(
          heroCompressor: FakeRecipePhotoCompressor(
            OwnRecipeFailure(OwnRecipeProblem.recipePhotoUnreadable),
          ),
          cardCompressor: FakeRecipePhotoCompressor(),
        ),
      );
      picker.picks = [aPhoto];
      await controller.addPhotos(RecipePhotoOrigin.library);
      expect(controller.form.photos, isEmpty);
      expect(controller.actionFailure, isA<OwnRecipeFailure>());
    });

    test('a refused camera is the member\'s to hear', () async {
      final controller = builder();
      picker.failWith = const OwnRecipeFailure(
        OwnRecipeProblem.recipePhotoRefused,
      );
      await controller.addPhotos(RecipePhotoOrigin.camera);
      expect(controller.actionFailure, isA<OwnRecipeFailure>());
      expect(controller.isAddingPhotos, isFalse);
    });
  });
}
