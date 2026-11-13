import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/list_scan/data/list_photo_picker.dart';
import 'package:nestprep/features/recipes/model/recipe_draft_reading.dart';
import 'package:nestprep/features/recipes/model/recipe_form.dart';
import 'package:nestprep/features/recipes/model/recipe_import_way.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/state/recipe_import_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_list_scan.dart';
import '../../../support/fake_recipe_import.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeRecipePageReader reader;
  late FakeRecipeDrafter drafter;
  late FakeListPhotoPicker picker;

  setUp(() {
    reader = FakeRecipePageReader();
    drafter = FakeRecipeDrafter();
    picker = FakeListPhotoPicker();
  });

  RecipeImportController make({RecipeImportWay way = RecipeImportWay.link}) {
    final controller = RecipeImportController(
      pageReader: reader,
      drafter: drafter,
      photoPicker: picker,
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

      await controller.pick(ListPhotoSource.photos);
      expect(picker.asked, [ListPhotoSource.photos]);
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

  group('a photo', () {
    test('sends only once one is picked, and asks nothing of a site', () async {
      drafter.reading = RecipeDraftReading(
        draft: aBobotieDraft(
          origin: RecipeOrigin.photo,
          sourceUrl: null,
          sourceName: null,
        ),
        callsLeft: 3,
      );
      final controller = make(way: RecipeImportWay.snap);
      await controller.pick(ListPhotoSource.camera);
      expect(drafter.photos.single, aListPhoto);
      expect(reader.asked, isEmpty);
      expect(controller.draft!.sourceUrl, isNull);
    });

    test('backing out of the picker changes nothing', () async {
      picker.next = null;
      final controller = make(way: RecipeImportWay.snap);
      await controller.pick(ListPhotoSource.camera);
      expect(controller.step, RecipeImportStep.start);
      expect(drafter.photos, isEmpty);
    });

    test(
      'a picker that will not open stays on the start, with a reason',
      () async {
        picker.failWith = const ListScanFailure(
          ListScanProblem.pickerUnavailable,
        );
        final controller = make(way: RecipeImportWay.snap);
        await controller.pick(ListPhotoSource.camera);
        expect(controller.step, RecipeImportStep.start);
        expect(controller.failure, isA<ListScanFailure>());
      },
    );

    test('a model that did not answer retries the same photo', () async {
      drafter.failWith = const AiFailure(AiProblem.aiUnavailable);
      final controller = make(way: RecipeImportWay.snap);
      await controller.pick(ListPhotoSource.photos);
      drafter.failWith = null;
      await controller.retry();
      expect(picker.asked, hasLength(1));
      expect(drafter.photos, hasLength(2));
    });
  });

  test('leaving mid-read is quiet', () async {
    reader.gate = Completer<void>();
    final controller = RecipeImportController(
      pageReader: reader,
      drafter: drafter,
      photoPicker: picker,
      householdId: Fixtures.householdId,
      way: RecipeImportWay.link,
    );
    final done = controller.readLink(aBobotieLink);
    controller.dispose();
    reader.gate!.complete();
    await expectLater(done, completes);
  });
}
