import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/data/recipe_pdf.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_course.dart';
import 'package:nestprep/features/recipes/model/recipe_document.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/state/own_recipe_importer.dart';
import 'package:nestprep/features/recipes/state/recipe_document_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_photo_intake.dart';
import 'package:nestprep/features/recipes/ui/recipe_document_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_own_recipes.dart';
import '../../../support/fake_recipe_document.dart';
import '../../../support/pump_screen.dart';

const _choose = ValueKey('recipe-document-choose');
const _import = ValueKey('recipe-document-import');
const _readShared = ValueKey('recipe-document-read-shared');

RecipeDraft _draft(String name, {List<String> steps = const ['Bake it.']}) =>
    RecipeDraft(
      name: name,
      placement: const {RecipeContext.dinner: RecipeCourse.main},
      ingredients: const [
        RecipeIngredient(name: 'Flour', quantity: 400, unit: 'g'),
      ],
      steps: steps,
    );

void main() {
  late FakeRecipeDocumentReader reader;
  late FakeSharedPdfInbox inbox;
  late FakeOwnRecipeRepository recipes;
  late List<RecipeDraft> finished;
  late int seen;

  setUp(() {
    reader = FakeRecipeDocumentReader();
    inbox = FakeSharedPdfInbox();
    recipes = FakeOwnRecipeRepository();
    finished = [];
    seen = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size((scale > 1 ? 360 : 390) * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      ChangeNotifierProvider(
        create: (_) => RecipeDocumentController(
          picker: FakeRecipePdfPicker(),
          inbox: inbox,
          rasterizer: FakePdfRasterizer(),
          reader: reader,
          importer: OwnRecipeImporter(
            ownRecipes: recipes,
            photoStore: FakeOwnRecipePhotoStore(),
            householdId: 'h1',
            viewerUid: 'u1',
          ),
          photoIntake: const RecipePhotoIntake(
            heroCompressor: FakeRecipePhotoCompressor(),
            cardCompressor: FakeRecipePhotoCompressor(),
          ),
          householdId: 'h1',
          work: workHere,
        ),
        child: RecipeDocumentScreen(
          onOpenBuilder: (_) {},
          onFinish: finished.add,
          onSeeRecipes: () => seen++,
          onBack: () {},
        ),
      ),
      providers: const [],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target, String list) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(ValueKey(list)),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> choosePdf(WidgetTester tester) async {
    await scrollTo(tester, find.byKey(_choose), 'recipe-document-start');
    await tester.tap(find.byKey(_choose));
    for (var frame = 0; frame < 20; frame++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('says the PDF stays on the phone and is not kept', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(RecipeDocumentCopy.privacyTitle), findsOneWidget);
    expect(find.text(RecipeDocumentCopy.privacyBody), findsOneWidget);
    expect(reader.scanned, isEmpty);
  });

  testWidgets('a shared PDF asks first, at 200% text, 360 wide, in the dark', (
    tester,
  ) async {
    inbox.filed['4F1C2D3E-1111'] = PickedPdf(
      bytes: Uint8List.fromList([1]),
      name: 'DOUGH IT EASY with a much longer name than most',
    );
    await pump(tester, brightness: Brightness.dark, scale: 2);
    final controller = tester
        .element(find.byType(RecipeDocumentScreen))
        .read<RecipeDocumentController>();
    await controller.receive('4F1C2D3E-1111');
    await tester.pumpAndSettle();
    expect(find.text(RecipeDocumentCopy.sharedTitle), findsOneWidget);
    expect(reader.scanned, isEmpty);

    await scrollTo(tester, find.byKey(_readShared), 'recipe-document-start');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(_readShared));
    for (var frame = 0; frame < 20; frame++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(reader.scanned, hasLength(1));
    expect(find.text(RecipeDocumentCopy.nothingTitle), findsOneWidget);
  });

  testWidgets('a PDF with no recipes says so, and adds nothing', (
    tester,
  ) async {
    await pump(tester);
    await choosePdf(tester);
    expect(find.text(RecipeDocumentCopy.nothingTitle), findsOneWidget);
    expect(recipes.saves, isEmpty);
  });

  group('fits at 200% text, 360 wide, in the dark', () {
    setUp(() {
      reader.scanAnswer = const RecipeDocumentScan(
        recipes: [
          FoundDocumentRecipe(
            name: 'Neapolitan pizza with a long name',
            summary: 'A thin, airy pizza baked in two parts at home.',
            pages: [2, 3],
            usesPages: [1],
          ),
          FoundDocumentRecipe(name: 'Focaccia', summary: '', pages: [3]),
        ],
        callsLeft: 80,
      );
    });

    testWidgets('choosing which recipes to add', (tester) async {
      await pump(tester, brightness: Brightness.dark, scale: 2);
      await choosePdf(tester);
      expect(find.text(RecipeDocumentCopy.foundTitle(2)), findsOneWidget);
      expect(find.text(RecipeDocumentCopy.importAction(2)), findsOneWidget);
      await scrollTo(tester, find.text('Focaccia'), 'recipe-document-choosing');
      await tester.tap(find.text('Focaccia'));
      await tester.pump();
      expect(find.text(RecipeDocumentCopy.importAction(1)), findsOneWidget);
    });

    testWidgets('adding them, with one to finish', (tester) async {
      reader.draftAnswers['Neapolitan pizza with a long name'] =
          DocumentRecipeReading(
            draft: _draft('Neapolitan pizza with a long name'),
            photo: null,
            callsLeft: 79,
          );
      reader.draftAnswers['Focaccia'] = DocumentRecipeReading(
        draft: _draft('Focaccia', steps: const []),
        photo: null,
        callsLeft: 78,
      );
      await pump(tester, brightness: Brightness.dark, scale: 2);
      await choosePdf(tester);
      await tester.tap(find.byKey(_import));
      for (var frame = 0; frame < 20; frame++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(RecipeDocumentCopy.doneTitle(1)), findsOneWidget);
      await scrollTo(
        tester,
        find.text(RecipeDocumentCopy.finishIt),
        'recipe-document-importing',
      );
      await tester.tap(find.text(RecipeDocumentCopy.finishIt));
      expect(finished.single.name, 'Focaccia');
      await scrollTo(
        tester,
        find.text(RecipeDocumentCopy.seeThem),
        'recipe-document-importing',
      );
      await tester.tap(find.text(RecipeDocumentCopy.seeThem));
      expect(seen, 1);
    });
  });
}
