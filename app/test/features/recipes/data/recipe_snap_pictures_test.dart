import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/recipes/data/recipe_snap_pictures.dart';
import 'package:nestprep/features/recipes/model/recipe_document.dart';
import 'package:nestprep/features/recipes/model/recipe_snap.dart';

Uint8List _picture(int width, int height) =>
    img.encodeJpg(img.Image(width: width, height: height), quality: 60);

RecipeSnap _cut(int width, int height, {int partRoom = RecipeSnap.maxParts}) {
  final cut = RecipeSnapPictures.cut(
    _picture(width, height),
    partRoom: partRoom,
  );
  return (cut as RecipeSnapReady).snap;
}

List<(int, int)> _sizes(RecipeSnap snap) => [
  for (final part in snap.parts)
    switch (img.decodeJpg(part)!) {
      final image => (image.width, image.height),
    },
];

void main() {
  const width = RecipeSnapPictures.partWidth;
  const height = RecipeSnapPictures.partHeight;

  group('where the parts start', () {
    test('a side that fits is one part', () {
      expect(RecipeSnapPictures.offsets(height, height), [0]);
      expect(RecipeSnapPictures.offsets(300, height), [0]);
    });

    test('a longer side is covered end to end, neighbours overlapping', () {
      for (final length in [821, 1365, 2216, 5000, 22055]) {
        final starts = RecipeSnapPictures.offsets(length, height);
        expect(starts.first, 0);
        expect(starts.last, length - height);
        for (var at = 1; at < starts.length; at += 1) {
          final shared = starts[at - 1] + height - starts[at];
          expect(
            shared,
            greaterThanOrEqualTo(height * RecipeSnapPictures.overlapShare - 1),
          );
        }
      }
    });
  });

  group('a photo, cut', () {
    test('a small one is left whole', () {
      expect(_sizes(_cut(600, 400)), [(600, 400)]);
    });

    test('a phone screenshot is three parts, top to bottom', () {
      final snap = _cut(1170, 2532);
      expect(_sizes(snap), List.filled(3, (width, height)));
    });

    test('a cookbook page is two', () {
      expect(_cut(3024, 4032).parts, hasLength(2));
    });

    test('a wide photo of an open book is cut both ways', () {
      final snap = _cut(4032, 3024);
      expect(_sizes(snap), List.filled(4, (width, height)));
    });

    test('a long scrolling screenshot keeps its width', () {
      final snap = _cut(1080, 9000);
      expect(snap.parts, hasLength(12));
      expect(snap.whole, isNull);
      expect(_sizes(snap).toSet(), {(width, height)});
    });

    test('a noisy part is pressed harder until it is small enough', () {
      final noisy = img.Image(width: 1024, height: 820);
      final random = Random(7);
      for (final pixel in noisy) {
        pixel.setRgb(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
      }
      final atFull = img.encodeJpg(noisy, quality: 80);
      expect(atFull.length, greaterThan(RecipeSnap.maxPartBytes));
      final cut = RecipeSnapPictures.cut(
        img.encodeJpg(noisy, quality: 95),
        partRoom: RecipeSnap.maxParts,
      );
      if (cut case RecipeSnapReady(:final snap)) {
        expect(
          snap.parts.single.length,
          lessThanOrEqualTo(RecipeSnap.maxPartBytes),
        );
      } else {
        expect(cut, isA<RecipeSnapUnreadable>());
      }
    });

    test('an ordinary photo is also kept whole, as one was always sent', () {
      final screenshot = img.decodeJpg(_cut(1170, 2532).whole!)!;
      expect((screenshot.width, screenshot.height), (1017, 2200));
      final page = img.decodeJpg(_cut(3024, 4032).whole!)!;
      expect((page.width, page.height), (1650, 2200));
      final small = img.decodeJpg(_cut(600, 400).whole!)!;
      expect((small.width, small.height), (600, 400));
    });

    test('carries a square thumbnail', () {
      final thumbnail = img.decodeJpg(_cut(1170, 2532).thumbnail)!;
      expect(thumbnail.width, RecipeSnapPictures.thumbnailEdge);
      expect(thumbnail.height, RecipeSnapPictures.thumbnailEdge);
    });
  });

  test('more parts than there is room for is too long, not cut short', () {
    expect(
      RecipeSnapPictures.cut(_picture(1170, 2532), partRoom: 2),
      isA<RecipeSnapTooLong>(),
    );
    expect(
      RecipeSnapPictures.cut(_picture(1170, 2532), partRoom: 3),
      isA<RecipeSnapReady>(),
    );
  });

  test('no part carries a screenshot’s colour profile', () {
    final screenshot = img.Image(width: 1206, height: 2622)
      ..iccProfile = img.IccProfile(
        'Display P3',
        img.IccProfileCompression.none,
        Uint8List(536),
      );
    final cut = RecipeSnapPictures.cut(
      img.encodePng(screenshot),
      partRoom: RecipeSnap.maxParts,
    );
    final snap = (cut as RecipeSnapReady).snap;
    for (final jpeg in [...snap.parts, snap.whole!, snap.thumbnail]) {
      expect(String.fromCharCodes(jpeg).contains('ICC_PROFILE'), isFalse);
    }
  });

  group('the dish’s photo, cut out of the parts', () {
    /// A white page 1024 wide, three parts tall (tops 0, 698, 1396), with a
    /// photograph at rows 500 to 1400 and columns 100 to 900: across a seam.
    RecipeSnap page() {
      final image = img.Image(width: 1024, height: 2216)
        ..clear(img.ColorRgb8(255, 255, 255));
      final random = Random(3);
      for (var y = 500; y < 1400; y += 1) {
        for (var x = 100; x < 900; x += 1) {
          image.setPixelRgb(x, y, random.nextInt(200), 90, 60);
        }
      }
      final cut = RecipeSnapPictures.cut(
        img.encodePng(image),
        partRoom: RecipeSnap.maxParts,
      );
      return (cut as RecipeSnapReady).snap;
    }

    (int, int) cutOut(RecipeSnap snap, RecipeSnapDish dish) {
      final photo = img.decodeJpg(RecipeSnapPictures.dishPhoto(snap, dish)!)!;
      return (photo.width, photo.height);
    }

    DocumentPhotoBox box(int top, int left, int bottom, int right) =>
        DocumentPhotoBox(top: top, left: left, bottom: bottom, right: right);

    test('remembers where every part sits', () {
      final layout = page().layout;
      expect((layout.width, layout.height), (1024, 2216));
      expect(layout.tops, [0, 698, 1396]);
      expect(layout.originOf(2), (0, 1396));
    });

    test('grows across a seam to the photograph’s real edge', () {
      final (width, height) = cutOut(
        page(),
        RecipeSnapDish(photo: 1, part: 2, box: box(0, 98, 856, 879)),
      );
      expect(width, closeTo(800, 3));
      expect(height, closeTo(900, 3));
    });

    test('stays inside its part when no edge is on a seam', () {
      final (_, height) = cutOut(
        page(),
        RecipeSnapDish(photo: 1, part: 2, box: box(100, 98, 600, 879)),
      );
      expect(height, closeTo(410, 2));
    });

    test('a box on the photo read whole is the photo’s own', () {
      final (width, height) = cutOut(
        page(),
        RecipeSnapDish(photo: 1, box: box(226, 98, 632, 879)),
      );
      expect(width, closeTo(800, 3));
      expect(height, closeTo(900, 3));
    });

    test('is none for a part that is not there, or a sliver', () {
      final snap = page();
      expect(
        RecipeSnapPictures.dishPhoto(
          snap,
          RecipeSnapDish(photo: 1, part: 4, box: box(0, 0, 500, 500)),
        ),
        isNull,
      );
      expect(
        RecipeSnapPictures.dishPhoto(
          snap,
          RecipeSnapDish(photo: 1, part: 1, box: box(100, 100, 120, 900)),
        ),
        isNull,
      );
    });
  });

  test('bytes that are no picture are unreadable', () {
    expect(
      RecipeSnapPictures.cut(Uint8List.fromList([1, 2, 3]), partRoom: 40),
      isA<RecipeSnapUnreadable>(),
    );
    expect(
      RecipeSnapPictures.cut(Uint8List(0), partRoom: 40),
      isA<RecipeSnapUnreadable>(),
    );
  });
}
