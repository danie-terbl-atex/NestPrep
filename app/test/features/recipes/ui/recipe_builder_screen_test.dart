import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_source.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_form.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/state/recipe_builder_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_image_picks.dart';
import 'package:nestprep/features/recipes/state/recipe_photo_intake.dart';
import 'package:nestprep/features/recipes/ui/recipe_builder_row.dart';
import 'package:nestprep/features/recipes/ui/recipe_builder_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/links/external_link_opener.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_link_opener.dart';
import '../../../support/fake_meal_repository.dart';
import '../../../support/fake_own_recipes.dart';
import '../../../support/fake_recipe_import.dart';
import '../../../support/fake_recipe_photos.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/recipe_fixtures.dart';

void main() {
  late FakeOwnRecipeRepository recipes;
  late FakeOwnRecipePhotoStore store;
  late FakeRecipePhotoPicker picker;
  late FakeRecipePhotoSource photos;
  late FakeMealRepository meals;
  late RecipeBuilderController controller;
  late int done;

  setUp(() {
    recipes = FakeOwnRecipeRepository();
    store = FakeOwnRecipePhotoStore();
    picker = FakeRecipePhotoPicker();
    photos = FakeRecipePhotoSource();
    meals = FakeMealRepository();
    done = 0;
  });

  tearDown(() => meals.close());

  Future<void> pump(
    WidgetTester tester, {
    Recipe? editing,
    RecipeDraft? draft,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size((scale > 1 ? 360 : 390) * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    controller = RecipeBuilderController(
      ownRecipes: recipes,
      photoStore: store,
      photoPicker: picker,
      photoIntake: const RecipePhotoIntake(
        heroCompressor: FakeRecipePhotoCompressor(),
        cardCompressor: FakeRecipePhotoCompressor(),
      ),
      photoSource: photos,
      mealRepository: meals,
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
      familySize: 4,
      editing: editing,
      draft: draft,
    );
    addTearDown(controller.dispose);
    await pumpScreen(
      tester,
      ChangeNotifierProvider.value(
        value: controller,
        child: RecipeBuilderScreen(onDone: () => done++),
      ),
      providers: [Provider<RecipePhotoSource>.value(value: photos)],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  Finder list() => find.byType(Scrollable).first;

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 300, scrollable: list());
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await scrollTo(tester, find.byKey(const ValueKey('recipe-save')));
    await tester.tap(find.byKey(const ValueKey('recipe-save')));
    await tester.pumpAndSettle();
  }

  void fill() => controller.update(
    (form) => form
        .copyWith(name: 'Bobotie')
        .withMeal(RecipeContext.dinner, isOn: true)
        .withLine(name: 'Mince')
        .withStep('Bake it.'),
  );

  group('validation', () {
    testWidgets('says nothing until somebody tries to save', (tester) async {
      await pump(tester);
      expect(
        find.text(OwnRecipeCopy.missing(RecipeFormProblem.noName)),
        findsNothing,
      );
      await tapSave(tester);

      expect(recipes.saves, isEmpty);
      expect(done, 0);
      expect(find.text(OwnRecipeCopy.fixTheMarked), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(OwnRecipeCopy.missing(RecipeFormProblem.noName)),
        -300,
        scrollable: list(),
      );
      expect(
        find.text(OwnRecipeCopy.missing(RecipeFormProblem.noName)),
        findsOneWidget,
      );
    });

    testWidgets('a problem goes as soon as it is fixed', (tester) async {
      await pump(tester);
      await tapSave(tester);
      fill();
      await tester.pumpAndSettle();
      expect(find.text(OwnRecipeCopy.fixTheMarked), findsNothing);
    });
  });

  group('adding lines', () {
    testWidgets('an ingredient goes in with its amount, unit and note, and the '
        'sheet stays for the next', (tester) async {
      await pump(tester);
      await scrollTo(tester, find.byKey(const ValueKey('recipe-add-line')));
      await tester.tap(find.byKey(const ValueKey('recipe-add-line')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('recipe-line-name')),
        'Onions',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-line-amount')),
        '1 1/2',
      );
      await tester.tap(find.text('kg'));
      await tester.enterText(
        find.byKey(const ValueKey('recipe-line-note')),
        'chopped',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-line-submit')));
      await tester.pumpAndSettle();

      final line = controller.form.ingredients.single;
      expect(line.name, 'Onions');
      expect(line.quantity, 1.5);
      expect(line.unit, 'kg');
      expect(line.note, 'chopped');
      expect(find.byKey(const ValueKey('recipe-line-name')), findsOneWidget);
    });

    testWidgets('an amount past the server\'s limit is said on the field', (
      tester,
    ) async {
      await pump(tester);
      await scrollTo(tester, find.byKey(const ValueKey('recipe-add-line')));
      await tester.tap(find.byKey(const ValueKey('recipe-add-line')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recipe-line-name')),
        'Flour',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-line-amount')),
        '20000',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-line-submit')));
      await tester.pumpAndSettle();
      expect(find.text(OwnRecipeCopy.amountTooBig), findsOneWidget);
      expect(controller.form.lines, isEmpty);
    });

    testWidgets('a step goes in, and tapping it changes it', (tester) async {
      await pump(tester);
      await scrollTo(tester, find.byKey(const ValueKey('recipe-add-step')));
      await tester.tap(find.byKey(const ValueKey('recipe-add-step')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recipe-text-field')),
        'Fry.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-text-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-text-done')));
      await tester.pumpAndSettle();
      expect(controller.form.steps.single.text, 'Fry.');

      await tester.tap(find.text('Fry.'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recipe-text-field')),
        'Bake.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-text-submit')));
      await tester.pumpAndSettle();
      expect(controller.form.steps.single.text, 'Bake.');
    });
  });

  group('reordering', () {
    void threeLines() => controller.update(
      (form) => form
          .withLine(name: 'aaa')
          .withLine(name: 'bbb')
          .withLine(name: 'ccc'),
    );

    testWidgets('dragging a handle moves the row', (tester) async {
      await pump(tester);
      threeLines();
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('aaa'));

      final handle = find
          .descendant(
            of: find.ancestor(
              of: find.text('aaa'),
              matching: find.byType(NestListRow),
            ),
            matching: find.byIcon(LucideIcons.gripVertical),
          )
          .first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 50));
      final rowHeight = tester
          .getSize(find.byType(RecipeBuilderRow).first)
          .height;
      await gesture.moveBy(Offset(0, rowHeight / 2));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(Offset(0, rowHeight * 1.5));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.form.lines.first.name, 'bbb');
      expect(controller.form.lines.map((line) => line.name).toSet(), {
        'aaa',
        'bbb',
        'ccc',
      });
    });

    testWidgets(
      'a screen reader can move a row too, and only where it can go',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester);
        threeLines();
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('aaa'));

        SemanticsNode nodeOf(String title) {
          SemanticsNode? node = tester.getSemantics(find.text(title));
          while (node != null) {
            final actions = node.getSemanticsData().customSemanticsActionIds;
            if (actions != null && actions.isNotEmpty) return node;
            node = node.parent;
          }
          throw StateError('no row with actions for $title');
        }

        Set<String> actionsOf(SemanticsNode node) => {
          for (final id
              in node.getSemanticsData().customSemanticsActionIds ?? <int>[])
            CustomSemanticsAction.getAction(id)!.label!,
        };

        expect(actionsOf(nodeOf('aaa')), {OwnRecipeCopy.moveDown});
        expect(actionsOf(nodeOf('bbb')), {
          OwnRecipeCopy.moveUp,
          OwnRecipeCopy.moveDown,
        });
        expect(actionsOf(nodeOf('ccc')), {OwnRecipeCopy.moveUp});

        final first = nodeOf('aaa');
        first.owner!.performAction(
          first.id,
          SemanticsAction.customAction,
          CustomSemanticsAction.getIdentifier(
            const CustomSemanticsAction(label: OwnRecipeCopy.moveDown),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.form.lines.map((line) => line.name), [
          'bbb',
          'aaa',
          'ccc',
        ]);
        semantics.dispose();
      },
    );

    testWidgets('rows keep their identity through a move', (tester) async {
      await pump(tester);
      threeLines();
      final ids = [for (final entry in controller.form.entries) entry.id];
      controller.update((form) => form.withEntryMoved(0, 2));
      await tester.pumpAndSettle();
      expect(
        [for (final entry in controller.form.entries) entry.id],
        [ids[1], ids[2], ids[0]],
      );
      await scrollTo(tester, find.byKey(ValueKey(ids[0])));
      expect(find.byKey(ValueKey(ids[0])), findsOneWidget);
    });
  });

  group('allergens', () {
    NestChip chip(WidgetTester tester, Allergen allergen) =>
        tester.widget<NestChip>(
          find.byKey(ValueKey('recipe-allergen-${allergen.name}')),
        );

    testWidgets('follow the words, can be added to, and never taken away', (
      tester,
    ) async {
      await pump(tester);
      await scrollTo(tester, find.text(RecipeCopy.allergensHeader));

      expect(chip(tester, Allergen.egg).isSelected, isFalse);
      controller.update((form) => form.withLine(name: 'Eggs'));
      await tester.pumpAndSettle();
      expect(chip(tester, Allergen.egg).isSelected, isTrue);
      expect(chip(tester, Allergen.egg).onTap, isNull);

      await scrollTo(tester, find.byKey(const ValueKey('recipe-allergen-soy')));
      await tester.tap(find.byKey(const ValueKey('recipe-allergen-soy')));
      await tester.pumpAndSettle();
      expect(chip(tester, Allergen.soy).isSelected, isTrue);
      expect(controller.form.alsoContains, {Allergen.soy});

      await tester.tap(find.byKey(const ValueKey('recipe-allergen-soy')));
      await tester.pumpAndSettle();
      expect(controller.form.alsoContains, isEmpty);
      expect(controller.derivedAllergens, {Allergen.egg});
    });

    testWidgets('an allergen the member added stays when the words catch up, '
        'and can\'t then be taken off', (tester) async {
      await pump(tester);
      controller
        ..update((form) => form.withAllergenToggled(Allergen.egg))
        ..update((form) => form.withLine(name: 'Eggs'));
      await scrollTo(tester, find.text(RecipeCopy.allergensHeader));
      await tester.pumpAndSettle();
      expect(chip(tester, Allergen.egg).onTap, isNull);
      expect(chip(tester, Allergen.egg).isSelected, isTrue);
    });
  });

  group('leaving', () {
    testWidgets('with nothing changed goes straight back', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip(AppCopy.back).first);
      await tester.pumpAndSettle();
      expect(done, 1);
    });

    testWidgets('with changes asks first', (tester) async {
      await pump(tester);
      fill();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppCopy.back).first);
      await tester.pumpAndSettle();
      expect(find.text(OwnRecipeCopy.leaveTitle), findsOneWidget);
      expect(done, 0);

      await tester.tap(find.text(OwnRecipeCopy.leaveCancel));
      await tester.pumpAndSettle();
      expect(done, 0);
      expect(controller.isDirty, isTrue);

      await tester.tap(find.byTooltip(AppCopy.back).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(OwnRecipeCopy.leaveConfirm));
      await tester.pumpAndSettle();
      expect(done, 1);
    });

    testWidgets('a system back with changes asks too', (tester) async {
      await pump(tester);
      fill();
      await tester.pumpAndSettle();
      final isHandled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(isHandled, isTrue);
      expect(find.text(OwnRecipeCopy.leaveTitle), findsOneWidget);
    });

    testWidgets('a draft already has something to lose', (tester) async {
      await pump(tester, draft: const RecipeDraft(name: 'Malva'));
      await tester.tap(find.byTooltip(AppCopy.back).first);
      await tester.pumpAndSettle();
      expect(find.text(OwnRecipeCopy.leaveTitle), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('a good save says so and goes', (tester) async {
      await pump(tester);
      fill();
      await tester.pumpAndSettle();
      await tapSave(tester);
      expect(recipes.saves, hasLength(1));
      expect(done, 1);
      expect(find.text(OwnRecipeCopy.saved), findsOneWidget);
    });

    testWidgets('a refusal stays with everything still typed, and says why', (
      tester,
    ) async {
      await pump(tester);
      fill();
      recipes.failWith = const OwnRecipeFailure(
        OwnRecipeProblem.recipeLimitReached,
      );
      await tester.pumpAndSettle();
      await tapSave(tester);
      expect(done, 0);
      expect(
        find.text(OwnRecipeCopy.problem(OwnRecipeProblem.recipeLimitReached)),
        findsOneWidget,
      );
      expect(controller.form.name, 'Bobotie');
    });
  });

  group('from a read', () {
    Future<void> pumpDraft(
      WidgetTester tester, {
      required RecipeDraft draft,
      required FakeLinkOpener opener,
    }) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      controller = RecipeBuilderController(
        ownRecipes: recipes,
        photoStore: store,
        photoPicker: picker,
        photoIntake: const RecipePhotoIntake(
          heroCompressor: FakeRecipePhotoCompressor(),
          cardCompressor: FakeRecipePhotoCompressor(),
        ),
        photoSource: photos,
        mealRepository: meals,
        householdId: Fixtures.householdId,
        viewerUid: Fixtures.samUid,
        familySize: 4,
        draft: draft,
      );
      addTearDown(controller.dispose);
      await pumpScreen(
        tester,
        ChangeNotifierProvider.value(
          value: controller,
          child: RecipeBuilderScreen(onDone: () => done++),
        ),
        providers: [
          Provider<RecipePhotoSource>.value(value: photos),
          Provider<ExternalLinkOpener>.value(value: opener),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('cut short says so, and opens the original', (tester) async {
      final opener = FakeLinkOpener();
      await pumpDraft(
        tester,
        opener: opener,
        draft: aBobotieDraft(cutShort: true),
      );
      expect(find.text(OwnRecipeCopy.cutShort), findsOneWidget);
      await tester.tap(find.text(OwnRecipeCopy.openOriginal));
      await tester.pumpAndSettle();
      expect(opener.opened, [Uri.parse(aBobotieLink)]);
    });

    testWidgets('cut short from a photo has nothing to link to', (
      tester,
    ) async {
      await pumpDraft(
        tester,
        opener: FakeLinkOpener(),
        draft: aBobotieDraft(
          cutShort: true,
          origin: RecipeOrigin.photo,
          sourceUrl: null,
          sourceName: null,
        ),
      );
      expect(find.text(OwnRecipeCopy.cutShort), findsOneWidget);
      expect(find.text(OwnRecipeCopy.openOriginal), findsNothing);
    });

    testWidgets('not cut short says nothing', (tester) async {
      await pumpDraft(tester, opener: FakeLinkOpener(), draft: aBobotieDraft());
      expect(find.byKey(const ValueKey('recipe-cut-short')), findsNothing);
    });

    group('with pictures from the page', () {
      const first = 'https://cdn.example.com/1.jpg';
      const second = 'https://cdn.example.com/2.jpg';
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M/AAAMA'
        'BAEBAM4bAQAAAABJRU5ErkJggg==',
      );

      Future<RecipeImagePicks> pumpPicks(
        WidgetTester tester,
        Map<String, Uint8List?> answers, {
        Brightness brightness = Brightness.light,
        double scale = 1,
      }) async {
        tester.view.physicalSize = Size((scale > 1 ? 360 : 390) * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        controller = RecipeBuilderController(
          ownRecipes: recipes,
          photoStore: store,
          photoPicker: picker,
          photoIntake: const RecipePhotoIntake(
            heroCompressor: FakeRecipePhotoCompressor(),
            cardCompressor: FakeRecipePhotoCompressor(),
          ),
          photoSource: photos,
          mealRepository: meals,
          householdId: Fixtures.householdId,
          viewerUid: Fixtures.samUid,
          familySize: 4,
          draft: aBobotieDraft(),
        );
        addTearDown(controller.dispose);
        final picks = RecipeImagePicks(
          builder: controller,
          fetcher: FakeRecipeImageFetcher(answers),
          intake: const RecipePhotoIntake(
            heroCompressor: FakeRecipePhotoCompressor(),
            cardCompressor: FakeRecipePhotoCompressor(),
          ),
          urls: answers.keys.toList(),
          credit: 'drizzleanddip.com',
          sourceUrl: aBobotieLink,
        );
        addTearDown(picks.dispose);
        await pumpScreen(
          tester,
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: controller),
              ChangeNotifierProvider.value(value: picks),
            ],
            child: RecipeBuilderScreen(onDone: () => done++),
          ),
          providers: [Provider<RecipePhotoSource>.value(value: photos)],
          brightness: brightness,
          textScale: scale,
        );
        await tester.pumpAndSettle();
        return picks;
      }

      testWidgets('the first is in, and the row can add or take out', (
        tester,
      ) async {
        await pumpPicks(tester, {first: bytes, second: bytes});
        expect(find.text(RecipeImportCopy.picturesTitle), findsOneWidget);
        expect(controller.form.photos, hasLength(1));

        await tester.tap(find.byKey(const ValueKey(second)));
        await tester.pumpAndSettle();
        expect(controller.form.photos, hasLength(2));

        await tester.tap(find.byKey(const ValueKey(first)));
        await tester.tap(find.byKey(const ValueKey(second)));
        await tester.pumpAndSettle();
        expect(controller.form.photos, isEmpty);
      });

      testWidgets('none that could be had means no row and no picture', (
        tester,
      ) async {
        await pumpPicks(tester, {first: null, second: null});
        expect(find.text(RecipeImportCopy.picturesTitle), findsNothing);
        expect(controller.form.photos, isEmpty);
      });

      testWidgets('fits at 200% text, 360 wide, in the dark', (tester) async {
        await pumpPicks(
          tester,
          {first: bytes, second: bytes},
          brightness: Brightness.dark,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('with no servings asks, rather than inventing some', (
      tester,
    ) async {
      await pumpDraft(
        tester,
        opener: FakeLinkOpener(),
        draft: aBobotieDraft(servings: null),
      );
      expect(controller.form.servings, isEmpty);

      await tapSave(tester);
      expect(recipes.saves, isEmpty);
      final asking = find.text(
        OwnRecipeCopy.missing(RecipeFormProblem.badServings),
      );
      await tester.scrollUntilVisible(asking, -300, scrollable: list());
      expect(asking, findsOneWidget);

      controller.update((form) => form.copyWith(servings: '8'));
      await tapSave(tester);
      expect(recipes.saves.single.recipe.servings, 8);
    });
  });

  group('prefilled', () {
    testWidgets('a draft opens on its words, and says when it was cut short', (
      tester,
    ) async {
      await pump(
        tester,
        draft: const RecipeDraft(
          name: 'Malva pudding',
          ingredients: [RecipeIngredient(name: 'Apricot jam')],
          steps: ['Bake it.'],
          cutShort: true,
        ),
      );
      expect(find.text(OwnRecipeCopy.cutShort), findsOneWidget);
      expect(find.text('Malva pudding'), findsOneWidget);
      await scrollTo(tester, find.text('Apricot jam'));
      expect(find.text('Apricot jam'), findsOneWidget);
    });

    testWidgets('editing opens on the recipe, photos and all', (tester) async {
      await pump(
        tester,
        editing: RecipeFixtures.own(
          photo: RecipeFixtures.ownPhoto('abcdefgh'),
          gallery: [RecipeFixtures.ownPhoto('ijklmnop')],
        ),
      );
      expect(find.text(OwnRecipeCopy.editTitle), findsOneWidget);
      expect(find.text(OwnRecipeCopy.coverTag), findsOneWidget);
      expect(controller.form.name, RecipeFixtures.own().name);
      expect(photos.asked, contains(RecipeFixtures.ownPhoto('abcdefgh').card));
    });
  });

  group('photos', () {
    testWidgets('many picked, first is cover, one can become it, one can go', (
      tester,
    ) async {
      picker.picks = [_fixturePhoto(), _fixturePhoto()];
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-photo-choose')));
      await tester.pumpAndSettle();
      expect(controller.form.photos, hasLength(2));
      expect(find.text(OwnRecipeCopy.coverTag), findsOneWidget);

      final second = controller.form.photos[1].photoId;
      await tester.tap(find.text(OwnRecipeCopy.makeCover));
      await tester.pumpAndSettle();
      expect(controller.form.photos.first.photoId, second);

      await tester.tap(find.byTooltip(OwnRecipeCopy.removePhoto(2)));
      await tester.pumpAndSettle();
      expect(controller.form.photos.single.photoId, second);
    });

    testWidgets('fits a photo row at 200% text, 360 wide, in the dark', (
      tester,
    ) async {
      picker.picks = [_fixturePhoto()];
      await pump(tester, brightness: Brightness.dark, scale: 2);
      await tester.tap(find.byKey(const ValueKey('recipe-photo-choose')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(picker.limits.single, 6);
    });
  });

  testWidgets('fits every section at 200% text, 360 wide, in the dark', (
    tester,
  ) async {
    await pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      editing: RecipeFixtures.own(
        notes: 'Better the next day.',
        photo: RecipeFixtures.ownPhoto('abcdefgh'),
      ),
    );
    expect(tester.takeException(), isNull);
    controller.update(
      (form) => form
          .withHeading('A heading long enough to wrap on a small phone')
          .withLine(
            name: 'An ingredient with a long name and a note',
            amount: 1.5,
            note: 'finely chopped, then fried until golden',
          )
          .withStep('A step long enough to wrap several times. ' * 6),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('recipe-add-line')));
    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.text(RecipeCopy.allergensHeader));
    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.byKey(const ValueKey('recipe-save')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('its problems fit at 200% text, 360 wide, in the dark', (
    tester,
  ) async {
    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tapSave(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(OwnRecipeCopy.fixTheMarked), findsOneWidget);
  });

  testWidgets('its sheets fit at 200% text, 360 wide, in the dark', (
    tester,
  ) async {
    await pump(tester, brightness: Brightness.dark, scale: 2);
    await scrollTo(tester, find.byKey(const ValueKey('recipe-add-line')));
    await tester.tap(find.byKey(const ValueKey('recipe-add-line')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Uint8List _fixturePhoto() =>
    File('test/fixtures/recipe_photo.jpg').readAsBytesSync();
