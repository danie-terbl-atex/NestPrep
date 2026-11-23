import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/list_scan/data/list_photo_picker.dart';
import 'package:nestprep/features/recipes/data/recipe_snap_picker.dart';
import 'package:nestprep/features/recipes/data/recipe_snap_pictures.dart';
import 'package:nestprep/features/recipes/model/recipe_document.dart';
import 'package:nestprep/features/recipes/model/recipe_draft_reading.dart';
import 'package:nestprep/features/recipes/model/recipe_form.dart';
import 'package:nestprep/features/recipes/model/recipe_import_way.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/model/recipe_snap.dart';
import 'package:nestprep/features/recipes/state/recipe_import_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_recipe_import.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeRecipePageReader reader;
  late FakeRecipeDrafter drafter;
  late FakeRecipeSnapPicker picker;

  setUp(() {
    reader = FakeRecipePageReader();
    drafter = FakeRecipeDrafter();
    picker = FakeRecipeSnapPicker();
  });

  RecipeImportController make({RecipeImportWay way = RecipeImportWay.link}) {
    final controller = RecipeImportController(
      pageReader: reader,
      drafter: drafter,
      snapPicker: picker,
      householdId: Fixtures.householdId,
      way: way,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('nothing leaves the phone until it is asked', () {
    final controller = make();
    expect(controller.step, RecipeImportStep.start);
    expect(reader.asked, isEmpty);
    expect(drafter.pages, isEmpty);
  });

  test('a link: reading the page, asking the model, a draft', () async {
    reader.gate = Completer<void>();
    drafter.gate = Completer<void>();
    final controller = make();
    final steps = <RecipeImportStep>[];
    controller.addListener(() => steps.add(controller.step));

    final done = controller.readLink(aBobotieLink);
    expect(controller.step, RecipeImportStep.readingPage);
    reader.gate!.complete();
    await pumpEventQueue();
    expect(controller.step, RecipeImportStep.askingAi);
    drafter.gate!.complete();
    await done;

    expect(steps, [
      RecipeImportStep.readingPage,
      RecipeImportStep.askingAi,
      RecipeImportStep.done,
    ]);
    expect(controller.draft?.name, 'Bobotie');
    expect(controller.callsLeft, 99);
    expect(reader.asked, [aBobotieLink]);
    expect(drafter.pages.single, aBobotiePage);
  });

  test(
    'a link that is not public goes nowhere, and is carried nowhere',
    () async {
      final controller = make();
      await controller.readLink('http://192.168.1.1/');
      expect(controller.step, RecipeImportStep.stopped);
      expect(
        controller.failure,
        isA<RecipeImportFailure>().having(
          (f) => f.problem,
          'problem',
          RecipeImportProblem.linkNotPublic,
        ),
      );
      expect(reader.asked, isEmpty);
      expect(controller.typedDraft.sourceUrl, isNull);
    },
  );

  group('a page that cannot be read', () {
    for (final problem in RecipeImportProblem.values) {
      test('$problem stops, offering a screenshot and typing', () async {
        reader.failWith = RecipeImportFailure(problem);
        final controller = make();
        await controller.readLink(aBobotieLink);
        expect(controller.step, RecipeImportStep.stopped);
        expect(controller.canSnapInstead, isTrue);
        expect(drafter.pages, isEmpty);
        expect(
          controller.canRetry,
          problem == RecipeImportProblem.pageUnreachable,
        );
      });
    }

    test('a site that refused is never asked again', () async {
      reader.failWith = const RecipeImportFailure(
        RecipeImportProblem.pageRefused,
      );
      final controller = make();
      await controller.readLink(aBobotieLink);
      await controller.retry();
      expect(reader.asked, hasLength(1));
    });

    test('a site that was only slow is', () async {
      reader.failWith = const RecipeImportFailure(
        RecipeImportProblem.pageUnreachable,
      );
      final controller = make();
      await controller.readLink(aBobotieLink);
      reader.failWith = null;
      await controller.retry();
      expect(reader.asked, hasLength(2));
      expect(controller.step, RecipeImportStep.done);
    });

    test('Type it carries the link', () async {
      reader.failWith = const RecipeImportFailure(
        RecipeImportProblem.pageRefused,
      );
      final controller = make();
      await controller.readLink('https://www.allrecipes.com/recipe/1/');
      final draft = controller.typedDraft;
      expect(draft.sourceUrl, 'https://www.allrecipes.com/recipe/1/');
      expect(draft.sourceName, 'allrecipes.com');
      expect(draft.origin, RecipeOrigin.typed);
      expect(draft.servings, RecipeForm.defaultServings);
      expect(const RecipeForm().servings, '${RecipeForm.defaultServings}');
    });

    test('a screenshot carries the link into the draft', () async {
      reader.failWith = const RecipeImportFailure(
        RecipeImportProblem.pageRefused,
      );
      drafter.reading = RecipeDraftReading(
        draft: aBobotieDraft(
          origin: RecipeOrigin.photo,
          sourceUrl: null,
          sourceName: null,
        ),
        callsLeft: 90,
      );
      final controller = make();
      await controller.readLink('https://www.allrecipes.com/recipe/1/');

      controller.useScreenshot();
      expect(controller.way, RecipeImportWay.snap);
      expect(controller.step, RecipeImportStep.start);
      expect(controller.failure, isNull);

      await controller.addPhotos(ListPhotoSource.photos);
      expect(picker.asked.single.source, ListPhotoSource.photos);
      await controller.readPhotos();
      expect(drafter.photos, hasLength(1));
      final draft = controller.draft!;
      expect(draft.origin, RecipeOrigin.photo);
      expect(draft.sourceUrl, 'https://www.allrecipes.com/recipe/1/');
      expect(draft.sourceName, 'allrecipes.com');
    });

    test('a private DNS answer is not carried either', () async {
      reader.failWith = const RecipeImportFailure(
        RecipeImportProblem.linkNotPublic,
      );
      final controller = make();
      await controller.readLink(aBobotieLink);
      expect(controller.typedDraft.sourceUrl, isNull);
    });
  });

  group('the model', () {
    test('saying it is no recipe stops, with the same two ways out', () async {
      drafter.reading = const RecipeDraftReading(draft: null, callsLeft: 50);
      final controller = make();
      await controller.readLink(aBobotieLink);
      expect(controller.step, RecipeImportStep.stopped);
      expect(
        controller.failure,
        isA<RecipeImportFailure>().having(
          (f) => f.problem,
          'problem',
          RecipeImportProblem.noRecipe,
        ),
      );
      expect(controller.canRetry, isFalse);
      expect(controller.canSnapInstead, isTrue);
      expect(controller.typedDraft.sourceUrl, aBobotieLink);
      expect(controller.callsLeft, 50);
    });

    test('not answering is retried without going back to the site', () async {
      drafter.failWith = const AiFailure(AiProblem.aiUnavailable);
      final controller = make();
      await controller.readLink(aBobotieLink);
      expect(controller.canRetry, isTrue);

      drafter.failWith = null;
      await controller.retry();
      expect(controller.step, RecipeImportStep.done);
      expect(reader.asked, hasLength(1));
      expect(drafter.pages, hasLength(2));
    });

    for (final problem in [AiProblem.aiLimitReached, AiProblem.aiSwitchedOff]) {
      test('$problem offers only typing', () async {
        drafter.failWith = AiFailure(problem);
        final controller = make();
        await controller.readLink(aBobotieLink);
        expect(controller.canRetry, isFalse);
        expect(controller.canSnapInstead, isFalse);
      });
    }

    test('declining is not retried', () async {
      drafter.failWith = const AiFailure(AiProblem.aiDeclined);
      final controller = make();
      await controller.readLink(aBobotieLink);
      expect(controller.canRetry, isFalse);
      expect(controller.canSnapInstead, isTrue);
    });
  });

  group('photos', () {
    RecipeImportController snapping() => make(way: RecipeImportWay.snap);

    test('are gathered first, and only read when asked', () async {
      drafter.reading = RecipeDraftReading(
        draft: aBobotieDraft(
          origin: RecipeOrigin.photo,
          sourceUrl: null,
          sourceName: null,
        ),
        callsLeft: 3,
      );
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.camera);
      await controller.addPhotos(ListPhotoSource.photos);
      expect(controller.snaps, hasLength(2));
      expect(controller.step, RecipeImportStep.start);
      expect(drafter.photos, isEmpty);

      await controller.readPhotos();
      expect(drafter.photos.single, controller.snaps);
      expect(reader.asked, isEmpty);
      expect(controller.draft!.sourceUrl, isNull);
    });

    test('the dish’s own photo is cut out and added to the draft', () async {
      final screenshot = img.Image(width: 1024, height: 2216)
        ..clear(img.ColorRgb8(255, 255, 255));
      final grain = Random(5);
      for (var y = 500; y < 1400; y += 1) {
        for (var x = 0; x < 1024; x += 1) {
          screenshot.setPixelRgb(x, y, 120 + grain.nextInt(100), 90, 60);
        }
      }
      final cut = RecipeSnapPictures.cut(
        img.encodePng(screenshot),
        partRoom: RecipeSnap.maxParts,
      );
      picker.next = RecipeSnapPick(snaps: [(cut as RecipeSnapReady).snap]);
      drafter.reading = RecipeDraftReading(
        draft: aBobotieDraft(origin: RecipeOrigin.photo, sourceUrl: null),
        callsLeft: 3,
        dish: const RecipeSnapDish(
          photo: 1,
          part: 2,
          box: DocumentPhotoBox(top: 0, left: 0, bottom: 856, right: 1000),
        ),
      );
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.photos);
      await controller.readPhotos();

      final hero = img.decodeJpg(controller.draft!.photos.single.hero.bytes)!;
      expect(hero.width / hero.height, closeTo(1024 / 900, 0.02));
    });

    test('a dish photo that cannot be cut leaves the recipe as read', () async {
      drafter.reading = RecipeDraftReading(
        draft: aBobotieDraft(origin: RecipeOrigin.photo, sourceUrl: null),
        callsLeft: 3,
        dish: const RecipeSnapDish(
          photo: 1,
          part: 1,
          box: DocumentPhotoBox(top: 0, left: 0, bottom: 500, right: 500),
        ),
      );
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.camera);
      await controller.readPhotos();
      expect(controller.step, RecipeImportStep.done);
      expect(controller.draft!.photos, isEmpty);
    });

    test('the picker is told how much room is left', () async {
      picker.next = RecipeSnapPick(snaps: [aSnap(parts: 3), aSnap(parts: 2)]);
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.photos);
      await controller.addPhotos(ListPhotoSource.photos);
      expect(picker.asked.map((ask) => (ask.photoRoom, ask.partRoom)), [
        (RecipeSnap.maxPhotos, RecipeSnap.maxParts),
        (RecipeSnap.maxPhotos - 2, RecipeSnap.maxParts - 5),
      ]);
    });

    test('eight photos is full, and taking one out makes room', () async {
      picker.next = RecipeSnapPick(
        snaps: List.generate(RecipeSnap.maxPhotos, (_) => aSnap()),
      );
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.photos);
      expect(controller.canAddPhoto, isFalse);
      await controller.addPhotos(ListPhotoSource.photos);
      expect(picker.asked, hasLength(1));

      controller.removePhoto(controller.snaps.first);
      expect(controller.snaps, hasLength(RecipeSnap.maxPhotos - 1));
      expect(controller.canAddPhoto, isTrue);
    });

    test('forty parts is full too', () async {
      picker.next = RecipeSnapPick(snaps: [aSnap(parts: RecipeSnap.maxParts)]);
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.photos);
      expect(controller.canAddPhoto, isFalse);
    });

    test('says it is adding while the photos are made ready', () async {
      picker.gate = Completer<void>();
      final controller = snapping();
      final adding = controller.addPhotos(ListPhotoSource.photos);
      expect(controller.isAdding, isTrue);
      await controller.readPhotos();
      picker.gate!.complete();
      await adding;
      expect(controller.isAdding, isFalse);
      expect(drafter.photos, isEmpty);
    });

    test('backing out of the picker changes nothing', () async {
      picker.next = const RecipeSnapPick();
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.camera);
      expect(controller.step, RecipeImportStep.start);
      expect(controller.snaps, isEmpty);
      expect(controller.failure, isNull);
    });

    test('a photo left out is said, and the others are kept', () async {
      picker.next = RecipeSnapPick(
        snaps: [aSnap()],
        problem: const RecipeImportFailure(RecipeImportProblem.photosTooLong),
      );
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.photos);
      expect(controller.snaps, hasLength(1));
      expect(controller.failure, isA<RecipeImportFailure>());
      expect(controller.step, RecipeImportStep.start);
    });

    test(
      'a picker that will not open stays on the start, with a reason',
      () async {
        picker.failWith = const ListScanFailure(
          ListScanProblem.pickerUnavailable,
        );
        final controller = snapping();
        await controller.addPhotos(ListPhotoSource.camera);
        expect(controller.step, RecipeImportStep.start);
        expect(controller.failure, isA<ListScanFailure>());
        expect(controller.isAdding, isFalse);
      },
    );

    test('a model that did not answer retries the same photos', () async {
      drafter.failWith = const AiFailure(AiProblem.aiUnavailable);
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.photos);
      await controller.readPhotos();
      drafter.failWith = null;
      await controller.retry();
      expect(picker.asked, hasLength(1));
      expect(drafter.photos, hasLength(2));
      expect(drafter.photos.last, drafter.photos.first);
    });

    test('changing the photos after a failure keeps them', () async {
      drafter.reading = const RecipeDraftReading(draft: null, callsLeft: 1);
      final controller = snapping();
      await controller.addPhotos(ListPhotoSource.photos);
      await controller.readPhotos();
      expect(controller.step, RecipeImportStep.stopped);
      controller.useScreenshot();
      expect(controller.step, RecipeImportStep.start);
      expect(controller.snaps, hasLength(1));
    });
  });

  test('leaving mid-read is quiet', () async {
    reader.gate = Completer<void>();
    final controller = RecipeImportController(
      pageReader: reader,
      drafter: drafter,
      snapPicker: picker,
      householdId: Fixtures.householdId,
      way: RecipeImportWay.link,
    );
    final done = controller.readLink(aBobotieLink);
    controller.dispose();
    reader.gate!.complete();
    await expectLater(done, completes);
  });
}
