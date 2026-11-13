import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/data/recipe_pdf.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_document.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/model/recipe_photo_cuts.dart';
import 'package:nestprep/features/recipes/state/own_recipe_importer.dart';
import 'package:nestprep/features/recipes/state/recipe_document_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_photo_intake.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/photos/compressed_photo.dart';

import '../../../support/fake_own_recipes.dart';
import '../../../support/fake_recipe_document.dart';

RecipeDraft _draft(String name, {List<String> steps = const ['Bake it.']}) =>
    RecipeDraft(
      name: name,
      placement: const {RecipeContext.dinner: RecipeCourse.side},
      ingredients: const [
        RecipeIngredient(name: 'Flour', quantity: 400, unit: 'g'),
      ],
      steps: steps,
      origin: RecipeOrigin.document,
      sourceName: 'Dough it easy',
    );

DocumentRecipeReading _reading(RecipeDraft draft, {DocumentPhoto? photo}) =>
    DocumentRecipeReading(draft: draft, photo: photo, callsLeft: 70);

const _focaccia = FoundDocumentRecipe(
  name: 'Focaccia',
  summary: 'Bread.',
  pages: [3],
  usesPages: [1],
);
const _pizza = FoundDocumentRecipe(name: 'Pizza', summary: '', pages: [2]);

void main() {
  late FakeRecipePdfPicker picker;
  late FakeSharedPdfInbox inbox;
  late FakePdfRasterizer rasterizer;
  late FakeRecipeDocumentReader reader;
  late FakeOwnRecipeRepository recipes;
  late FakeOwnRecipePhotoStore photos;
  late RecipeDocumentController controller;

  setUp(() {
    picker = FakeRecipePdfPicker();
    inbox = FakeSharedPdfInbox();
    rasterizer = FakePdfRasterizer();
    reader = FakeRecipeDocumentReader();
    recipes = FakeOwnRecipeRepository();
    photos = FakeOwnRecipePhotoStore();
    controller = RecipeDocumentController(
      picker: picker,
      inbox: inbox,
      rasterizer: rasterizer,
      reader: reader,
      importer: OwnRecipeImporter(
        ownRecipes: recipes,
        photoStore: photos,
        householdId: 'h1',
        viewerUid: 'u1',
      ),
      photoIntake: const RecipePhotoIntake(
        heroCompressor: FakeRecipePhotoCompressor(),
        cardCompressor: FakeRecipePhotoCompressor(),
      ),
      householdId: 'h1',
      work: workHere,
    );
  });

  tearDown(() => controller.dispose());

  test(
    'sends every page once to find the recipes, then waits for a choice',
    () async {
      reader.scanAnswer = const RecipeDocumentScan(
        recipes: [_focaccia, _pizza],
        callsLeft: 90,
      );
      await controller.pick();
      expect(reader.scanned.single.map((page) => page.number), [1, 2, 3]);
      expect(controller.step, RecipeDocumentStep.choosing);
      expect([controller.isChosen(0), controller.isChosen(1)], [true, true]);
      expect(controller.thumbnailOf(_focaccia), isNotNull);
    },
  );

  test('a PDF shared from another app waits to be read, then reads like a '
      'chosen one', () async {
    inbox.filed['4F1C2D3E-1111'] = PickedPdf(
      bytes: Uint8List.fromList([1]),
      name: 'DOUGH IT EASY',
    );
    reader.scanAnswer = const RecipeDocumentScan(
      recipes: [_focaccia, _pizza],
      callsLeft: 90,
    );
    await controller.receive('4F1C2D3E-1111');
    expect(controller.step, RecipeDocumentStep.start);
    expect(controller.offeredName, 'DOUGH IT EASY');
    expect(controller.holdsDocument, isTrue);
    expect(reader.scanned, isEmpty);

    await controller.readOffered();
    expect(reader.scanned.single, hasLength(3));
    expect(controller.step, RecipeDocumentStep.choosing);
    expect(controller.offeredName, isNull);
  });

  test(
    'a share the phone no longer has says so, and choosing still works',
    () async {
      await controller.receive('4F1C2D3E-1111');
      expect(controller.step, RecipeDocumentStep.stopped);
      expect(
        controller.failure,
        const OwnRecipeFailure(OwnRecipeProblem.documentShareGone),
      );
      await controller.pick();
      expect(controller.step, RecipeDocumentStep.nothingFound);
    },
  );

  test(
    'a shared PDF it finds nothing in is let go, like a chosen one',
    () async {
      inbox.filed['4F1C2D3E-1111'] = PickedPdf(
        bytes: Uint8List.fromList([1]),
        name: 'Notes',
      );
      await controller.receive('4F1C2D3E-1111');
      await controller.readOffered();
      expect(controller.step, RecipeDocumentStep.nothingFound);
      expect(controller.holdsDocument, isFalse);
      expect(recipes.saves, isEmpty);
    },
  );

  test('finds nothing, adds nothing, and lets the PDF go', () async {
    await controller.pick();
    expect(controller.step, RecipeDocumentStep.nothingFound);
    expect(controller.holdsDocument, isFalse);
    expect(recipes.saves, isEmpty);
    expect(reader.drafted, isEmpty);
  });

  test(
    'a PDF of one recipe opens the builder with its photo, saving nothing',
    () async {
      reader.scanAnswer = const RecipeDocumentScan(
        recipes: [_focaccia],
        callsLeft: 90,
      );
      reader.draftAnswers['Focaccia'] = _reading(
        _draft('Focaccia'),
        photo: const DocumentPhoto(
          page: 3,
          box: DocumentPhotoBox(top: 500, left: 0, bottom: 1000, right: 1000),
        ),
      );
      await controller.pick();
      final draft = controller.builderDraft;
      expect(draft?.name, 'Focaccia');
      expect(draft?.photos, hasLength(1));
      expect(reader.drafted.single.pages.map((page) => page.number), [1, 3]);
      expect(reader.drafted.single.pages.map((page) => page.whole != null), [
        false,
        true,
      ]);
      expect(recipes.saves, isEmpty);
      expect(controller.holdsDocument, isFalse);
    },
  );

  test('saves each chosen recipe as it is, and only the chosen', () async {
    reader.scanAnswer = const RecipeDocumentScan(
      recipes: [_focaccia, _pizza],
      callsLeft: 90,
    );
    reader.draftAnswers['Focaccia'] = _reading(_draft('Focaccia'));
    await controller.pick();
    controller.toggle(1);
    await controller.importChosen();
    expect(reader.drafted.map((call) => call.recipeName), ['Focaccia']);
    expect(recipes.saves.single.recipe.name, 'Focaccia');
    expect(recipes.saves.single.recipe.servings, 4);
    expect(controller.rows.single.state, DocumentImportState.saved);
    expect(controller.savedCount, 1);
    expect(controller.holdsDocument, isFalse);
  });

  test('uploads a recipe’s photo before saving it', () async {
    reader.scanAnswer = const RecipeDocumentScan(
      recipes: [_focaccia, _pizza],
      callsLeft: 90,
    );
    reader.draftAnswers['Focaccia'] = _reading(
      _draft('Focaccia'),
      photo: const DocumentPhoto(
        page: 3,
        box: DocumentPhotoBox(top: 0, left: 0, bottom: 1000, right: 1000),
      ),
    );
    await controller.pick();
    controller.toggle(1);
    await controller.importChosen();
    final saved = recipes.saves.single;
    expect(photos.uploaded, hasLength(2));
    expect(photos.uploaded.first, contains(saved.recipeId));
    expect(saved.recipe.photo?.credit, 'Dough it easy');
  });

  test(
    'a recipe missing its method waits to be finished, the rest are saved',
    () async {
      reader.scanAnswer = const RecipeDocumentScan(
        recipes: [_focaccia, _pizza],
        callsLeft: 90,
      );
      reader.draftAnswers['Focaccia'] = _reading(
        _draft('Focaccia', steps: const []),
      );
      reader.draftAnswers['Pizza'] = _reading(_draft('Pizza'));
      await controller.pick();
      await controller.importChosen();
      expect(controller.rows.map((row) => row.state), [
        DocumentImportState.unfinished,
        DocumentImportState.saved,
      ]);
      expect(controller.rows.first.draft?.name, 'Focaccia');
      expect(recipes.saves.map((save) => save.recipe.name), ['Pizza']);
    },
  );

  test(
    'a recipe that failed keeps the PDF to try again, and then saves',
    () async {
      reader.scanAnswer = const RecipeDocumentScan(
        recipes: [_focaccia, _pizza],
        callsLeft: 90,
      );
      reader.draftAnswers['Focaccia'] = _reading(_draft('Focaccia'));
      reader.draftAnswers['Pizza'] = _reading(_draft('Pizza'));
      reader.draftFailures['Pizza'] = const AiFailure(AiProblem.aiUnavailable);
      await controller.pick();
      await controller.importChosen();
      expect(controller.rows.last.state, DocumentImportState.failed);
      expect(controller.holdsDocument, isTrue);
      await controller.retry(1);
      expect(controller.rows.last.state, DocumentImportState.saved);
      expect(controller.holdsDocument, isFalse);
    },
  );

  test('never picks more than the month’s reads left', () async {
    reader.scanAnswer = const RecipeDocumentScan(
      recipes: [_focaccia, _pizza],
      callsLeft: 1,
    );
    await controller.pick();
    expect(controller.chosenCount, 1);
    controller.toggle(1);
    expect(controller.isChosen(1), isFalse);
  });

  test('says why it stopped, and a backed-out picker does nothing', () async {
    reader.scanFailure = const AiFailure(AiProblem.aiLimitReached);
    await controller.pick();
    expect(controller.step, RecipeDocumentStep.stopped);
    expect(controller.failure, const AiFailure(AiProblem.aiLimitReached));
    expect(controller.holdsDocument, isFalse);

    picker.pdf = null;
    await controller.pick();
    expect(controller.step, RecipeDocumentStep.stopped);
  });

  test('stops saving once the screen has gone', () async {
    reader.scanAnswer = const RecipeDocumentScan(
      recipes: [_focaccia, _pizza],
      callsLeft: 90,
    );
    reader.draftAnswers['Focaccia'] = _reading(_draft('Focaccia'));
    reader.draftAnswers['Pizza'] = _reading(_draft('Pizza'));
    await controller.pick();
    final hold = reader.holdDrafts = Completer<void>();
    final importing = controller.importChosen();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isImporting, isTrue);
    controller.dispose();
    hold.complete();
    await importing;
    expect(recipes.saves, isEmpty);
    controller = RecipeDocumentController(
      picker: picker,
      inbox: inbox,
      rasterizer: rasterizer,
      reader: reader,
      importer: OwnRecipeImporter(
        ownRecipes: recipes,
        photoStore: photos,
        householdId: 'h1',
        viewerUid: 'u1',
      ),
      photoIntake: const RecipePhotoIntake(
        heroCompressor: FakeRecipePhotoCompressor(),
        cardCompressor: FakeRecipePhotoCompressor(),
      ),
      householdId: 'h1',
    );
  });

  test(
    'the builder takes a draft’s photos as new ones, credited to the PDF',
    () {
      final cuts = RecipePhotoCuts(
        card: CompressedPhoto(bytes: Uint8List(1), width: 1, height: 1),
        hero: CompressedPhoto(bytes: Uint8List(1), width: 1, height: 1),
      );
      final form = OwnRecipeImporter.savableForm(
        _draft('Focaccia').withPhotos([cuts]),
      );
      expect(form?.photos.single.credit, 'Dough it easy');
      expect(form?.toSave().origin, RecipeOrigin.document);
    },
  );
}
