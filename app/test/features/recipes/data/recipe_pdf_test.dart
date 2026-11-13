import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/recipes/data/callable_recipe_document_reader.dart';
import 'package:nestprep/features/recipes/data/recipe_pdf.dart';
import 'package:nestprep/features/recipes/data/recipe_pdf_document.dart';
import 'package:nestprep/features/recipes/data/recipe_pdf_pictures.dart';
import 'package:nestprep/features/recipes/model/recipe_document.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_recipe_document.dart';

PdfRasterPage _page(
  int width,
  int height, {
  List<int> pixel = const [0, 0, 0, 0],
}) {
  final rgba = Uint8List(width * height * 4);
  for (var at = 0; at < rgba.length; at += 4) {
    rgba.setRange(at, at + 4, pixel);
  }
  return PdfRasterPage(width: width, height: height, rgba: rgba);
}

void main() {
  final pdf = Uint8List.fromList([1]);

  group('a page picture', () {
    test(
      'is on white where the PDF draws nothing, as a JPEG cannot be clear',
      () {
        final white = RecipePdfPictures.onWhite(_page(2, 2));
        expect(white.getPixel(0, 0).r, 255);
        expect(white.getPixel(1, 1).b, 255);
      },
    );

    test('keeps what is drawn, premultiplied as both platforms give it', () {
      final red = RecipePdfPictures.onWhite(
        _page(1, 1, pixel: [200, 0, 0, 255]),
      );
      expect([red.getPixel(0, 0).r, red.getPixel(0, 0).g], [200, 0]);
      final half = RecipePdfPictures.onWhite(
        _page(1, 1, pixel: [100, 0, 0, 128]),
      );
      expect([half.getPixel(0, 0).r, half.getPixel(0, 0).g], [227, 127]);
    });

    test('is scaled to its long edge and never up', () {
      final big = img.decodeJpg(
        RecipePdfPictures.whole(_page(300, 400), longEdge: 200),
      )!;
      expect([big.width, big.height], [150, 200]);
      final small = img.decodeJpg(
        RecipePdfPictures.whole(_page(30, 40), longEdge: 200),
      )!;
      expect([small.width, small.height], [30, 40]);
    });

    test('halves overlap, so a line across the middle is whole in one', () {
      final (top, bottom) = RecipePdfPictures.halves(
        _page(100, 200),
        longEdge: 200,
      );
      expect(img.decodeJpg(top)!.height, 110);
      expect(img.decodeJpg(bottom)!.height, 110);
    });

    test('a photo is cut from its box on 0–1000', () {
      final photo = img.decodeJpg(
        RecipePdfPictures.cropped(
          _page(200, 400),
          const DocumentPhotoBox(top: 500, left: 0, bottom: 1000, right: 500),
        ),
      )!;
      expect([photo.width, photo.height], [100, 200]);
    });
  });

  group('an opened PDF', () {
    test('knows its pages from one small drawing', () async {
      final rasterizer = FakePdfRasterizer(pages: 4);
      final document = await RecipePdfDocument.open(
        rasterizer,
        pdf,
        work: workHere,
      );
      expect(document.pageCount, 4);
      expect(rasterizer.calls.single.pages, isNull);
    });

    test('refuses more than fifty pages, and one it cannot draw', () async {
      await expectLater(
        RecipePdfDocument.open(
          FakePdfRasterizer(pages: 51),
          pdf,
          work: workHere,
        ),
        throwsA(const OwnRecipeFailure(OwnRecipeProblem.documentTooLong)),
      );
      await expectLater(
        RecipePdfDocument.open(
          FakePdfRasterizer()..failWith = Exception('malformed'),
          pdf,
          work: workHere,
        ),
        throwsA(const OwnRecipeFailure(OwnRecipeProblem.documentUnreadable)),
      );
      await expectLater(
        RecipePdfDocument.open(
          FakePdfRasterizer(pages: 0),
          pdf,
          work: workHere,
        ),
        throwsA(const OwnRecipeFailure(OwnRecipeProblem.documentUnreadable)),
      );
    });

    test(
      'draws every page once to scan, numbered from 1, in batches',
      () async {
        final rasterizer = FakePdfRasterizer(pages: 10);
        final document = await RecipePdfDocument.open(
          rasterizer,
          pdf,
          work: workHere,
        );
        final pages = await document.scanPages().toList();
        expect(pages.map((page) => page.number), [
          for (var n = 1; n <= 10; n++) n,
        ]);
        expect(rasterizer.drawn.map((call) => call.pages), [
          [0, 1, 2, 3, 4, 5, 6, 7],
          [8, 9],
        ]);
        expect(img.decodeJpg(pages.first.jpeg)!.height, 768);
      },
    );

    test('draws a page shared by two recipes only once', () async {
      final rasterizer = FakePdfRasterizer(pages: 6);
      final document = await RecipePdfDocument.open(
        rasterizer,
        pdf,
        work: workHere,
      );
      final first = await document.readPages([1, 2, 3], wholes: {3});
      final second = await document.readPages([1, 2, 5], wholes: {5});
      expect(first.map((page) => page.whole != null), [false, false, true]);
      expect(second.map((page) => page.number), [1, 2, 5]);
      expect(rasterizer.drawn.map((call) => call.pages), [
        [0, 1, 2],
        [4],
      ]);
    });

    test('draws a photo so its crop is about 1400 across', () async {
      final rasterizer = FakePdfRasterizer(size: const Size(100, 200));
      final document = await RecipePdfDocument.open(
        rasterizer,
        pdf,
        work: workHere,
      );
      final photo = img.decodeJpg(
        await document.photo(
          const DocumentPhoto(
            page: 2,
            box: DocumentPhotoBox(top: 500, left: 0, bottom: 1000, right: 1000),
          ),
        ),
      )!;
      expect(photo.width, closeTo(1400, 30));
      expect(rasterizer.drawn.single.pages, [1]);
    });
  });

  group('the wire', () {
    test('a PDF is named for its file, without a copy’s number', () {
      expect(PickedPdf.nameOf('DOUGH IT EASY (1).pdf'), 'DOUGH IT EASY');
      expect(PickedPdf.nameOf('Bakes.PDF'), 'Bakes');
      expect(PickedPdf.nameOf('.pdf'), 'PDF');
    });

    test('a scan keeps recipes with a name and pages', () {
      final scan = CallableRecipeDocumentReader.scanFromWire({
        'callsLeft': 42,
        'recipes': [
          {
            'name': 'Focaccia',
            'summary': 'Bread.',
            'pages': [28, 29],
            'usesPages': [9],
          },
          {
            'name': '',
            'pages': [1],
          },
          {'name': 'No pages', 'pages': <int>[]},
        ],
      });
      expect(scan.callsLeft, 42);
      expect(scan.recipes.single.name, 'Focaccia');
      expect(scan.recipes.single.readPages, [9, 28, 29]);
    });

    test('a draft carries its photo box when there is one', () {
      final reading = CallableRecipeDocumentReader.readingFromWire({
        'isRecipe': true,
        'callsLeft': 3,
        'recipe': {
          'name': 'Focaccia',
          'origin': 'document',
          'sourceName': 'Book',
        },
        'photo': {
          'page': 31,
          'box': [560, 50, 888, 491],
        },
      });
      expect(reading.draft?.origin, RecipeOrigin.document);
      expect(reading.photo?.page, 31);
      expect(reading.photo?.box.bottom, 888);
      final noBox = CallableRecipeDocumentReader.readingFromWire({
        'isRecipe': true,
        'callsLeft': 3,
        'recipe': {'name': 'Focaccia'},
        'photo': {
          'page': 31,
          'box': [500, 50, 400, 491],
        },
      });
      expect(noBox.photo, isNull);
    });
  });
}
