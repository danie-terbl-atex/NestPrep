import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/app/backend_target.dart';
import 'package:nestprep/app/firebase_bootstrap.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/meal_planning/data/firestore_meal_repository.dart';
import 'package:nestprep/features/recipes/data/callable_own_recipe_repository.dart';
import 'package:nestprep/features/recipes/data/callable_recipe_drafter.dart';
import 'package:nestprep/features/recipes/data/firestore_recipe_repository.dart';
import 'package:nestprep/features/recipes/data/storage_own_recipe_photo_store.dart';
import 'package:nestprep/features/recipes/model/own_recipe_ids.dart';
import 'package:nestprep/features/recipes/model/own_recipe_photo_paths.dart';
import 'package:nestprep/features/recipes/model/own_recipe_save.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/model/recipe_page.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

const _household = 'demo-household';
const _password = 'nestprep';
const _parent = 'parent@nestprep.test';
const _helper = 'helper@nestprep.test';

Uint8List _jpeg() =>
    Uint8List.fromList(img.encodeJpg(img.Image(width: 8, height: 8)));

OwnRecipeSave _recipe({
  String name = 'Ouma se melktert',
  OwnRecipePhotoRef? photo,
  Set<Allergen> alsoContains = const {},
}) => OwnRecipeSave(
  name: name,
  summary: 'A family tart.',
  notes: 'Dust with cinnamon.',
  placement: const {RecipeContext.dinner: RecipeCourse.dessert},
  ingredients: const [
    RecipeIngredient(name: 'Sugar', quantity: 1, unit: 'cup'),
  ],
  steps: const ['Bake with the butter.'],
  servings: 8,
  prepMinutes: 20,
  cookMinutes: 40,
  origin: RecipeOrigin.typed,
  sourceUrl: null,
  sourceName: null,
  alsoContains: alsoContains,
  photo: photo,
  gallery: const [],
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseServices services;
  late CallableOwnRecipeRepository recipes;
  late StorageOwnRecipePhotoStore photos;
  late FirestoreRecipeRepository reader;

  Future<User> signIn(String email) async {
    await services.auth.signOut();
    final signedIn = await services.auth.signInWithEmailAndPassword(
      email: email,
      password: _password,
    );
    return signedIn.user!;
  }

  Future<Recipe?> ownRecipeOnceItIs(
    String id,
    bool Function(Recipe? recipe) settled,
  ) async {
    final list = await reader
        .watchOwnRecipes(_household)
        .firstWhere(
          (recipes) =>
              settled(recipes.where((recipe) => recipe.id == id).firstOrNull),
        )
        .timeout(const Duration(seconds: 15));
    return list.where((recipe) => recipe.id == id).firstOrNull;
  }

  setUpAll(() async {
    services = await bootstrapFirebase(BackendTarget.emulator);
    recipes = CallableOwnRecipeRepository(services.functions);
    photos = StorageOwnRecipePhotoStore(services.storage);
    reader = FirestoreRecipeRepository(services.firestore);
  });

  tearDownAll(() => services.auth.signOut());

  test(
    'a recipe saves with its photo, lists, edits, plans and deletes, for real',
    () async {
      final parent = await signIn(_parent);
      final id = OwnRecipeIds.newRecipeId();
      final photoId = OwnRecipeIds.newPhotoId();
      final card = OwnRecipePhotoPaths.card(_household, id, photoId);
      final hero = OwnRecipePhotoPaths.hero(_household, id, photoId);
      for (final path in [card, hero]) {
        await photos.upload(
          path: path,
          uploaderUid: parent.uid,
          bytes: _jpeg(),
        );
      }

      final withPhoto = _recipe(
        photo: OwnRecipePhotoRef(photoId: photoId),
        alsoContains: const {Allergen.egg},
      );
      await recipes.save(
        householdId: _household,
        recipeId: id,
        recipe: withPhoto,
      );
      await recipes.save(
        householdId: _household,
        recipeId: id,
        recipe: withPhoto,
      );

      final saved = await ownRecipeOnceItIs(id, (recipe) => recipe != null);
      expect(saved!.isOwn, isTrue);
      expect(saved.allergens, containsAll([Allergen.milk, Allergen.egg]));
      expect(saved.photo?.card, card);
      expect(
        await services.storage.ref(card).getData(),
        isNotNull,
        reason: 'the member reads their picture through the Storage rule',
      );

      final home = await services.firestore
          .collection('households')
          .doc(_household)
          .get();
      final profiles = home.data()!['profiles'] as Map<String, Object?>;
      final meals = FirestoreMealRepository(services.firestore);
      final mealId = await meals.addRecipeMeal(
        householdId: _household,
        link: HouseholdRecipeLink(id),
        name: withPhoto.name,
        ingredients: const [],
        addedBy: profiles[parent.uid]! as String,
      );
      final mealRef = services.firestore
          .collection('households')
          .doc(_household)
          .collection('meals')
          .doc(mealId);
      expect((await mealRef.get()).data()!['householdRecipeId'], id);

      await recipes.save(
        householdId: _household,
        recipeId: id,
        recipe: _recipe(name: 'Ouma se beste melktert'),
      );
      final edited = await ownRecipeOnceItIs(
        id,
        (recipe) => recipe?.name == 'Ouma se beste melktert',
      );
      expect(edited!.allergens, isNot(contains(Allergen.egg)));
      expect((await mealRef.get()).data()!['name'], 'Ouma se beste melktert');
      await expectLater(
        services.storage.ref(card).getData(),
        throwsA(isA<FirebaseException>()),
        reason: 'a dropped photo leaves Storage on the next save',
      );

      await signIn(_helper);
      final seenByHelper = await services.firestore
          .collection('households')
          .doc(_household)
          .collection('recipes')
          .where('source', isEqualTo: 'own')
          .orderBy('name')
          .limit(300)
          .get(const GetOptions(source: Source.server));
      expect(
        seenByHelper.docs.map((doc) => doc.id),
        contains(id),
        reason: 'a helper with meals view lists the household\'s own recipes',
      );

      await signIn(_parent);
      await recipes.delete(householdId: _household, recipeId: id);
      expect(await ownRecipeOnceItIs(id, (recipe) => recipe == null), isNull);
      final unlinked = (await mealRef.get()).data()!;
      expect(unlinked.containsKey('householdRecipeId'), isFalse);
      await mealRef.delete();
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('a save naming a photo that was never uploaded is refused', () async {
    await signIn(_parent);
    await expectLater(
      recipes.save(
        householdId: _household,
        recipeId: OwnRecipeIds.newRecipeId(),
        recipe: _recipe(
          photo: OwnRecipePhotoRef(photoId: OwnRecipeIds.newPhotoId()),
        ),
      ),
      throwsA(
        isA<OwnRecipeFailure>().having(
          (failure) => failure.problem,
          'problem',
          OwnRecipeProblem.recipePhotoMissing,
        ),
      ),
    );
  });

  test('a page drafts through the callable and the canned model', () async {
    await signIn(_parent);
    final reading = await CallableRecipeDrafter(services.functions).fromPage(
      householdId: _household,
      page: const RecipePage(
        url: 'https://example.com/bobotie',
        title: 'Bobotie',
        jsonLd: ['{"@type":"Recipe","name":"Bobotie"}'],
        text: '',
        imageUrls: ['https://example.com/bobotie.jpg'],
      ),
    );
    expect(reading.draft, isNotNull);
    expect(reading.draft!.sourceName, 'example.com');
    expect(reading.draft!.candidateImageUrls, [
      'https://example.com/bobotie.jpg',
    ]);
  });
}
