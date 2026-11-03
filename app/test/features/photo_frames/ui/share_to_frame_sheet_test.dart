import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_directory.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_repository.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/frame_share_item.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';
import 'package:nestprep/features/photo_frames/state/pending_share.dart';
import 'package:nestprep/features/photo_frames/ui/share_to_frame_host.dart';
import 'package:nestprep/features/photo_frames/ui/share_to_frame_sheet.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_source.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cook_along_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_photo_frames.dart';
import '../../../support/fake_recipe_photos.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  const recipe = 'https://www.example.com/recipes/lemon-tart';
  final shareLink = Uri.parse(
    'nestprep://share?url=${Uri.encodeQueryComponent(recipe)}'
    '&title=${Uri.encodeQueryComponent('Lemon tart')}',
  );

  late StreamController<Uri> links;
  late PendingShare pending;
  late FakePhotoFrameRepository repository;
  late FakePhotoFrameDirectory directory;

  final kitchen = FrameFixtures.frame(panels: const FramePanels(share: true));
  final hall = FrameFixtures.frame(
    id: 'frame-hall',
    name: 'Hall frame',
    panels: const FramePanels(share: true),
  );
  final study = FrameFixtures.frame(id: 'frame-study', name: 'Study frame');
  final porch = FrameFixtures.frame(
    id: 'frame-porch',
    name: 'Porch frame',
    panels: const FramePanels(share: true),
    accepts: PhotoFrame.pageOnly,
  );

  setUp(() {
    links = StreamController<Uri>.broadcast();
    pending = PendingShare(links: links.stream);
    repository = FakePhotoFrameRepository();
    directory = FakePhotoFrameDirectory();
  });

  tearDown(() async {
    pending.dispose();
    await links.close();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const ShareToFrameHost(child: Scaffold(body: SizedBox.expand())),
    providers: [
      ChangeNotifierProvider<PendingShare>.value(value: pending),
      Provider<PhotoFrameRepository>.value(value: repository),
      Provider<PhotoFrameDirectory>.value(value: directory),
    ],
    view: view,
    brightness: brightness,
    textScale: scale,
  );

  Future<void> settleSheet(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> share(WidgetTester tester, [Uri? link]) async {
    links.add(link ?? shareLink);
    await settleSheet(tester);
  }

  Future<void> frames(WidgetTester tester, List<PhotoFrame> frames) async {
    repository.emit(frames);
    await tester.pumpAndSettle();
  }

  testWidgets('a shared page opens the sheet once, naming the page', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);

    expect(find.text(PhotoFrameCopy.showOnFrame), findsOneWidget);
    expect(find.text('Lemon tart'), findsOneWidget);
    expect(find.text('www.example.com'), findsOneWidget);
    expect(pending.page, isNull);
  });

  testWidgets('one frame with sharing on is one tap', (tester) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [kitchen, study]);

    expect(find.text(PhotoFrameCopy.chooseFrame), findsNothing);
    expect(find.text(study.name), findsNothing);
    await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
    await tester.pumpAndSettle();

    expect(directory.shared.single, (
      frameId: kitchen.id,
      url: recipe,
      title: 'Lemon tart',
    ));
    expect(find.text(PhotoFrameCopy.openingOn(kitchen.name)), findsOneWidget);

    await tester.tap(find.text(PhotoFrameCopy.done));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('several frames are a choice, and only those sharing', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [hall, kitchen, study]);

    expect(find.text(PhotoFrameCopy.chooseFrame), findsOneWidget);
    expect(find.text(hall.name), findsOneWidget);
    expect(find.text(kitchen.name), findsOneWidget);
    expect(find.text(study.name), findsNothing);

    await tester.tap(find.text(hall.name));
    await tester.pumpAndSettle();
    expect(directory.shared.single.frameId, hall.id);
    expect(find.text(PhotoFrameCopy.openingOn(hall.name)), findsOneWidget);
  });

  testWidgets('a page still goes to a frame that cannot cook along', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [porch]);

    expect(find.text(CookAlongCopy.updateToCookAlong), findsNothing);
    await tester.tap(find.text(PhotoFrameCopy.showOn(porch.name)));
    await tester.pumpAndSettle();
    expect(directory.shared.single.frameId, porch.id);
  });

  testWidgets('one tap at a time while it sends', (tester) async {
    directory.holdCalls = Completer<void>();
    await pump(tester);
    await share(tester);
    await frames(tester, [hall, kitchen]);

    await tester.tap(find.text(hall.name));
    await tester.pump();
    await tester.tap(find.text(kitchen.name));
    await tester.pump();
    directory.holdCalls!.complete();
    await tester.pumpAndSettle();

    expect(directory.shared.single.frameId, hall.id);
  });

  testWidgets('no frame with sharing on says where to switch it on', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [study]);

    expect(find.text(PhotoFrameCopy.noSharingFrames), findsOneWidget);
    expect(find.text(PhotoFrameCopy.noSharingFramesBody), findsOneWidget);
    expect(find.text(study.name), findsNothing);
  });

  testWidgets('somebody who is not family is told only family can', (
    tester,
  ) async {
    await pump(tester, view: Fixtures.view(viewerUid: Fixtures.thandiUid));
    await share(tester);

    expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsOneWidget);
    expect(find.byType(NestLoadingView), findsNothing);
    repository.emit([kitchen]);
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.showOn(kitchen.name)), findsNothing);
  });

  testWidgets('a share with no web link in it says so', (tester) async {
    await pump(tester);
    await share(tester, Uri.parse('nestprep://share?url=just%20some%20words'));

    expect(find.text(PhotoFrameCopy.noLinkShared), findsOneWidget);
  });

  testWidgets('an unreadable frame list offers a retry', (tester) async {
    await pump(tester);
    await share(tester);
    repository.failWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.retry), findsOneWidget);
    await tester.tap(find.text(AppCopy.retry));
    await tester.pump();
    expect(find.byType(NestLoadingView), findsOneWidget);
    await frames(tester, [kitchen]);
    expect(find.text(PhotoFrameCopy.showOn(kitchen.name)), findsOneWidget);
  });

  group(
    'a refusal is said in its own words, and another frame can be tried',
    () {
      for (final problem in [
        PhotoFrameProblem.frameNotFound,
        PhotoFrameProblem.sharingOff,
        PhotoFrameProblem.badLink,
        PhotoFrameProblem.framesOff,
        PhotoFrameProblem.tooManyAttempts,
      ]) {
        testWidgets(problem.name, (tester) async {
          directory.failWith = PhotoFrameFailure(problem);
          await pump(tester);
          await share(tester);
          await frames(tester, [hall, kitchen]);

          await tester.tap(find.text(hall.name));
          await tester.pumpAndSettle();
          expect(find.text(PhotoFrameCopy.problem(problem)), findsOneWidget);
          expect(find.text(PhotoFrameCopy.openingOn(hall.name)), findsNothing);

          directory.failWith = null;
          await tester.tap(find.text(kitchen.name));
          await tester.pumpAndSettle();
          expect(
            find.text(PhotoFrameCopy.openingOn(kitchen.name)),
            findsOneWidget,
          );
        });
      }

      testWidgets('notFamily, as only family can', (tester) async {
        directory.failWith = const PhotoFrameFailure(
          PhotoFrameProblem.notFamily,
        );
        await pump(tester);
        await share(tester);
        await frames(tester, [kitchen]);

        await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
        await tester.pumpAndSettle();
        expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsOneWidget);
      });
    },
  );

  testWidgets('a page shared while the sheet is open waits for it to close', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [kitchen]);
    await share(
      tester,
      Uri.parse('nestprep://share?url=https%3A%2F%2Fsecond.example.com'),
    );
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.done));
    await settleSheet(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('second.example.com'), findsOneWidget);
    expect(pending.page, isNull);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester, brightness: Brightness.dark, scale: 2);
    await share(tester);
    await frames(tester, [hall, kitchen]);

    expect(tester.takeException(), isNull);
    await tester.tap(find.text(hall.name));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('a recipe', () {
    const bobotie = FrameShareRecipe(
      recipeId: 'bobotie',
      name: 'Bobotie',
      people: 4,
      amounts: ['670 g', '1', null],
      cardPhotoPath: 'recipes/bobotie/card-abc123.jpg',
    );
    late FakeRecipePhotoSource photos;

    setUp(() => photos = FakeRecipePhotoSource());

    Future<void> open(
      WidgetTester tester, {
      HouseholdView? view,
      Brightness brightness = Brightness.light,
      double scale = 1,
    }) async {
      await pumpScreen(
        tester,
        const Scaffold(body: _OpenRecipe(recipe: bobotie)),
        providers: [
          Provider<PhotoFrameRepository>.value(value: repository),
          Provider<PhotoFrameDirectory>.value(value: directory),
          Provider<RecipePhotoSource>.value(value: photos),
        ],
        view: view,
        brightness: brightness,
        textScale: scale,
      );
      await tester.tap(find.byType(_OpenRecipe));
      await settleSheet(tester);
    }

    testWidgets('names the recipe, its people and shows its card photo', (
      tester,
    ) async {
      await open(tester);

      expect(find.text(PhotoFrameCopy.showOnFrame), findsOneWidget);
      expect(find.text('Bobotie'), findsOneWidget);
      expect(find.text(RecipeCopy.forPeople(4)), findsOneWidget);
      expect(photos.asked, contains(bobotie.cardPhotoPath));
    });

    testWidgets('one tap sends the recipe, never a link', (tester) async {
      await open(tester);
      await frames(tester, [kitchen, study]);

      await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
      await tester.pumpAndSettle();

      expect(directory.shared, isEmpty);
      expect(directory.payloads.single, {
        'householdId': Fixtures.householdId,
        'frameId': kitchen.id,
        'recipe': {
          'id': 'bobotie',
          'people': 4,
          'amounts': ['670 g', '1', null],
        },
      });
      expect(find.text(PhotoFrameCopy.openingOn(kitchen.name)), findsOneWidget);
      expect(find.text(CookAlongCopy.sentBody), findsOneWidget);
    });

    testWidgets('a frame that cannot cook along is listed, but not to tap', (
      tester,
    ) async {
      await open(tester);
      await frames(tester, [kitchen, porch]);

      expect(find.text(porch.name), findsOneWidget);
      expect(find.text(CookAlongCopy.updateToCookAlong), findsOneWidget);
      await tester.tap(find.text(porch.name));
      await tester.pumpAndSettle();
      expect(directory.payloads, isEmpty);

      await tester.tap(find.text(kitchen.name));
      await tester.pumpAndSettle();
      expect(directory.sharedRecipes.single.frameId, kitchen.id);
    });

    testWidgets('the only frame cannot cook along: the one tap is off', (
      tester,
    ) async {
      await open(tester);
      await frames(tester, [porch]);

      expect(find.text(CookAlongCopy.updateToCookAlong), findsOneWidget);
      final button = tester.widget<NestButton>(
        find.widgetWithText(NestButton, PhotoFrameCopy.showOn(porch.name)),
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.text(PhotoFrameCopy.showOn(porch.name)));
      await tester.pumpAndSettle();
      expect(directory.payloads, isEmpty);
    });

    testWidgets('a choice of frames lists only those sharing', (tester) async {
      await open(tester);
      await frames(tester, [hall, kitchen, study]);

      expect(find.text(study.name), findsNothing);
      await tester.tap(find.text(hall.name));
      await tester.pumpAndSettle();
      expect(directory.sharedRecipes.single.frameId, hall.id);
    });

    group('a refusal is said, and another frame can be tried', () {
      for (final problem in [
        PhotoFrameProblem.sharingOff,
        PhotoFrameProblem.frameCantOpen,
        PhotoFrameProblem.recipeNotFound,
        PhotoFrameProblem.badRecipe,
      ]) {
        testWidgets(problem.name, (tester) async {
          directory.failWith = PhotoFrameFailure(problem);
          await open(tester);
          await frames(tester, [hall, kitchen]);

          await tester.tap(find.text(hall.name));
          await tester.pumpAndSettle();
          expect(find.text(PhotoFrameCopy.problem(problem)), findsOneWidget);
          expect(find.text(PhotoFrameCopy.openingOn(hall.name)), findsNothing);

          directory.failWith = null;
          await tester.tap(find.text(kitchen.name));
          await tester.pumpAndSettle();
          expect(
            find.text(PhotoFrameCopy.openingOn(kitchen.name)),
            findsOneWidget,
          );
        });
      }
    });

    testWidgets('somebody who is not family is told only family can', (
      tester,
    ) async {
      await open(tester, view: Fixtures.view(viewerUid: Fixtures.thandiUid));

      expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsOneWidget);
      expect(repository.hasListener, isFalse);
    });

    testWidgets('survives dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await open(tester, brightness: Brightness.dark, scale: 2);
      await frames(tester, [hall, kitchen, porch]);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(hall.name));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _OpenRecipe extends StatelessWidget {
  const _OpenRecipe({required this.recipe});

  final FrameShareRecipe recipe;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => showShareToFrameSheet(context: context, item: recipe),
    child: const Text('Open'),
  );
}
