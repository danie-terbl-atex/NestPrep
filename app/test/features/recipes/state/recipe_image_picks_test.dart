import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/recipes/data/recipe_image_fetcher.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/state/recipe_builder_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_image_picks.dart';
import 'package:nestprep/features/recipes/state/recipe_photo_intake.dart';
import 'package:nestprep/shared/photos/compressed_photo.dart';
import 'package:nestprep/shared/photos/photo_compressor.dart';

import '../../../support/fake_meal_repository.dart';
import '../../../support/fake_own_recipes.dart';
import '../../../support/fake_recipe_import.dart';
import '../../../support/fake_recipe_photos.dart';
import '../../../support/household_fixtures.dart';

const _first = 'https://cdn.example.com/1.jpg';
const _second = 'https://cdn.example.com/2.jpg';
const _third = 'https://cdn.example.com/3.jpg';

final _bytes = Uint8List.fromList([1, 2, 3]);

void main() {
  late FakeOwnRecipeRepository recipes;
  late FakeOwnRecipePhotoStore store;
  late FakeMealRepository meals;
  late RecipeBuilderController builder;

  setUp(() {
    recipes = FakeOwnRecipeRepository();
    store = FakeOwnRecipePhotoStore();
    meals = FakeMealRepository();
    builder = RecipeBuilderController(
      ownRecipes: recipes,
      photoStore: store,
      photoPicker: FakeRecipePhotoPicker(),
      photoIntake: const RecipePhotoIntake(
        heroCompressor: FakeRecipePhotoCompressor(),
        cardCompressor: FakeRecipePhotoCompressor(),
      ),
      photoSource: FakeRecipePhotoSource(),
      mealRepository: meals,
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
      familySize: 4,
      draft: const RecipeDraft(name: 'Bobotie'),
    );
    builder.update(
      (form) => form
          .withMeal(RecipeContext.dinner, isOn: true)
          .withLine(name: 'Mince')
          .withStep('Bake it.')
          .copyWith(servings: '6'),
    );
  });

  tearDown(() async {
    builder.dispose();
    await meals.close();
  });

  RecipeImagePicks picksOver(
    RecipeImageFetcher fetcher, {
    List<String> urls = const [_first, _second],
    RecipePhotoIntake intake = const RecipePhotoIntake(
      heroCompressor: FakeRecipePhotoCompressor(),
      cardCompressor: FakeRecipePhotoCompressor(),
    ),
  }) {
    final picks = RecipeImagePicks(
      builder: builder,
      fetcher: fetcher,
      intake: intake,
      urls: urls,
      credit: 'drizzleanddip.com',
      sourceUrl: aBobotieLink,
    );
    addTearDown(picks.dispose);
    return picks;
  }

  test('the first is chosen, credited to the site and linked to it', () async {
    final picks = picksOver(
      FakeRecipeImageFetcher({_first: _bytes, _second: _bytes}),
    );
    await pumpEventQueue();

    expect(picks.shown, hasLength(2));
    expect(picks.isChosen(picks.shown.first), isTrue);
    expect(picks.isChosen(picks.shown.last), isFalse);
    final photo = builder.form.photos.single;
    expect(photo.credit, 'drizzleanddip.com');
    expect(photo.sourceUrl, aBobotieLink);
  });

  test('another can be added, and the first taken out, leaving none', () async {
    final picks = picksOver(
      FakeRecipeImageFetcher({_first: _bytes, _second: _bytes}),
    );
    await pumpEventQueue();
    final [first, second] = picks.shown;

    picks.toggle(second);
    expect(builder.form.photos, hasLength(2));
    expect(picks.isChosen(second), isTrue);

    picks.toggle(first);
    picks.toggle(second);
    expect(builder.form.photos, isEmpty);
    expect(picks.isChosen(first), isFalse);
  });

  test('removing it from the photos un-chooses it in the row', () async {
    final picks = picksOver(FakeRecipeImageFetcher({_first: _bytes}));
    await pumpEventQueue();
    final first = picks.shown.single;
    final photoId = builder.form.photos.single.photoId;

    builder.update((form) => form.withoutPhoto(photoId));
    expect(picks.isChosen(first), isFalse);
    picks.toggle(first);
    expect(picks.isChosen(first), isTrue);
  });

  test('a failed download is silently no picture, and fails nothing', () async {
    final picks = picksOver(FakeRecipeImageFetcher());
    await pumpEventQueue();

    expect(picks.shown, isEmpty);
    expect(builder.form.photos, isEmpty);
    expect(builder.actionFailure, isNull);

    expect(await builder.save(), isTrue);
    expect(recipes.saves.single.recipe.photo, isNull);
  });

  test('a failed first picks no other in its place', () async {
    final picks = picksOver(FakeRecipeImageFetcher({_second: _bytes}));
    await pumpEventQueue();

    expect(picks.shown, hasLength(1));
    expect(picks.isChosen(picks.shown.single), isFalse);
    expect(builder.form.photos, isEmpty);
  });

  test('a picture that will not decode is no picture', () async {
    final picks = picksOver(
      FakeRecipeImageFetcher({
        _first: Uint8List.fromList([1, 2, 3, 4]),
      }),
      urls: const [_first],
      intake: const RecipePhotoIntake(),
    );
    await untilLoaded(picks);

    expect(picks.shown, isEmpty);
    expect(builder.form.photos, isEmpty);
  });

  test(
    'a real picture goes through the real pipeline, off this isolate',
    () async {
      final picks = picksOver(
        FakeRecipeImageFetcher({
          _first: img.encodePng(img.Image(width: 8, height: 6)),
        }),
        urls: const [_first],
        intake: const RecipePhotoIntake(),
      );
      await untilLoaded(picks);

      expect(builder.form.photos, hasLength(1));
      expect(picks.shown.single.cuts?.hero.width, 8);
    },
  );

  test('a compressor that blows up is no picture', () async {
    final picks = picksOver(
      FakeRecipeImageFetcher({_first: _bytes}),
      urls: const [_first],
      intake: const RecipePhotoIntake(heroCompressor: _ThrowingCompressor()),
    );
    await pumpEventQueue();
    expect(picks.shown, isEmpty);
  });

  test('Save waits for the chosen picture rather than losing it', () async {
    final fetcher = FakeRecipeImageFetcher({_first: _bytes})
      ..gate = Completer<void>();
    picksOver(fetcher, urls: const [_first]);

    final saving = builder.save();
    await pumpEventQueue();
    expect(builder.isSaving, isTrue);
    expect(recipes.saves, isEmpty);

    fetcher.gate!.complete();
    expect(await saving, isTrue);
    expect(recipes.saves.single.recipe.photo, isNotNull);
    expect(store.uploaded, hasLength(2));
  });

  test('never past the photos a recipe can keep', () async {
    final urls = [for (var i = 0; i < 6; i++) 'https://cdn.example.com/$i.jpg'];
    final picks = picksOver(
      FakeRecipeImageFetcher({for (final url in urls) url: _bytes}),
      urls: urls,
    );
    await pumpEventQueue();
    picks.shown.skip(1).forEach(picks.toggle);
    expect(builder.form.photos, hasLength(6));

    builder.update((form) => form.withoutPhoto(form.photos.first.photoId));
    expect(builder.form.canAddPhoto, isTrue);
    expect(picks.isChosen(picks.shown.first), isFalse);
  });

  test('leaving while they load is quiet', () async {
    final fetcher = FakeRecipeImageFetcher({_first: _bytes, _third: _bytes})
      ..gate = Completer<void>();
    final picks = RecipeImagePicks(
      builder: builder,
      fetcher: fetcher,
      intake: const RecipePhotoIntake(
        heroCompressor: FakeRecipePhotoCompressor(),
        cardCompressor: FakeRecipePhotoCompressor(),
      ),
      urls: const [_first, _third],
      credit: null,
      sourceUrl: null,
    );
    picks.dispose();
    fetcher.gate!.complete();
    await pumpEventQueue();
    expect(builder.form.photos, isEmpty);
  });
}

Future<void> untilLoaded(RecipeImagePicks picks) async {
  for (var i = 0; i < 200; i++) {
    if (picks.shown.every((pick) => !pick.isLoading)) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('the picture never finished loading');
}

final class _ThrowingCompressor implements PhotoCompressor {
  const _ThrowingCompressor();

  @override
  Future<CompressedPhoto> compress(Uint8List original) async =>
      throw StateError('boom');
}
