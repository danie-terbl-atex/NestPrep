import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_directory.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_repository.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';
import 'package:nestprep/features/photo_frames/state/frame_availability.dart';
import 'package:nestprep/features/photo_frames/ui/cook_along_teaser_sheet.dart';
import 'package:nestprep/features/recipes/model/recipe_scale.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/features/recipes/ui/recipe_frame_share.dart';
import 'package:nestprep/features/recipes/ui/recipe_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cook_along_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_photo_frames.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/recipe_fixtures.dart';
import '../../../support/recipe_harness.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late RecipeHarness harness;
  late FakePhotoFrameRepository frames;
  late FakePhotoFrameDirectory directory;

  final kitchen = FrameFixtures.frame(panels: const FramePanels(share: true));

  setUp(() {
    harness = RecipeHarness();
    frames = FakePhotoFrameRepository();
    directory = FakePhotoFrameDirectory();
  });

  tearDown(() async {
    await harness.close();
    await frames.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    bool framesOn = true,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size((scale > 1 ? 360 : 390) * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      ChangeNotifierProxyProvider<
        RecipeCatalogueController,
        RecipePageController
      >(
        create: (_) => RecipePageController(
          mealRepository: harness.meals,
          householdId: Fixtures.householdId,
          memberId: Fixtures.samMemberId,
          recipeId: RecipeFixtures.bobotie.id,
          familySize: 4,
        ),
        update: (_, catalogue, page) => page!..followCatalogue(catalogue),
        child:
            ChangeNotifierProxyProvider<
              FeatureFlagsController,
              FrameAvailability
            >(
              create: (context) => FrameAvailability(
                photoFrameRepository: frames,
                householdId: Fixtures.householdId,
                isFamily: context.read<HouseholdView>().permissions.isFamily,
              ),
              update: (_, flags, availability) =>
                  availability!
                    ..followFlag(framesOn: flags.isOn(FeatureFlag.photoFrames)),
              child: RecipeScreen(onBack: () {}),
            ),
      ),
      providers: [
        ...harness.providers,
        featureFlagsProvider(defaultOn: framesOn),
        Provider<PhotoFrameRepository>.value(value: frames),
        Provider<PhotoFrameDirectory>.value(value: directory),
      ],
      view: view,
      brightness: brightness,
      textScale: scale,
    );
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    await tester.pumpAndSettle();
  }

  Future<void> scrollToScaler(WidgetTester tester) async {
    final page = find.byType(Scrollable).first;
    final scaler = find.text(RecipeCopy.cookingFor.toUpperCase());
    await tester.dragUntilVisible(scaler, page, const Offset(0, -250));
    await tester.pumpAndSettle();
    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final y = tester.getCenter(scaler).dy;
    await tester.drag(page, Offset(0, height * 0.15 - y));
    await tester.pumpAndSettle();
  }

  Future<void> emit(WidgetTester tester, List<PhotoFrame> list) async {
    frames.emit(list);
    await tester.pumpAndSettle();
  }

  Finder openButton() =>
      find.widgetWithText(NestButton, CookAlongCopy.openOnFrame);

  testWidgets('hidden while the frames are loading', (tester) async {
    await pump(tester);
    await scrollToScaler(tester);

    expect(find.text(CookAlongCopy.openOnFrame), findsNothing);
  });

  testWidgets('hidden for somebody who is not family, who never listens', (
    tester,
  ) async {
    await pump(tester, view: Fixtures.view(viewerUid: Fixtures.thandiUid));
    await scrollToScaler(tester);

    expect(frames.hasListener, isFalse);
    expect(find.text(CookAlongCopy.openOnFrame), findsNothing);
  });

  testWidgets('hidden while photo frames are switched off', (tester) async {
    await pump(tester, framesOn: false);
    await scrollToScaler(tester);

    expect(frames.hasListener, isFalse);
    expect(find.text(CookAlongCopy.openOnFrame), findsNothing);
  });

  testWidgets('no frame: a teaser that opens the cook-along sheet', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, []);
    await scrollToScaler(tester);

    expect(openButton(), findsNothing);
    expect(find.text(CookAlongCopy.openOnFrame), findsOneWidget);
    expect(find.text(CookAlongCopy.homeTag), findsOneWidget);

    await tester.tap(find.text(CookAlongCopy.openOnFrame));
    await tester.pumpAndSettle();

    expect(find.byType(CookAlongTeaserSheet), findsOneWidget);
    expect(find.text(CookAlongCopy.teaserTitle), findsWidgets);
    for (final line in [
      CookAlongCopy.teaserSteps,
      CookAlongCopy.teaserTimers,
      CookAlongCopy.teaserScaled,
    ]) {
      expect(find.text(line), findsOneWidget);
    }

    await tester.tap(find.text(CookAlongCopy.notNow));
    await tester.pumpAndSettle();
    expect(find.byType(CookAlongTeaserSheet), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('the teaser’s Link a frame goes to the photo frames', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, []);
    await scrollToScaler(tester);

    await tester.tap(find.text(CookAlongCopy.openOnFrame));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CookAlongCopy.linkFrame));
    await tester.pumpAndSettle();

    expect(find.byType(CookAlongTeaserSheet), findsNothing);
    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('a frame: the button opens Show on frame at the page’s people', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, [kitchen]);
    await scrollToScaler(tester);

    expect(find.text(CookAlongCopy.homeTag), findsNothing);
    expect(find.text(RecipeCopy.forPeople(4)), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RecipeCopy.addPerson));
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.forPeople(5)), findsOneWidget);

    await tester.tap(openButton());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(PhotoFrameCopy.showOnFrame), findsOneWidget);
    expect(find.text(RecipeFixtures.bobotie.name), findsWidgets);
    await emit(tester, [kitchen]);
    await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
    await tester.pumpAndSettle();

    final sent = directory.sharedRecipes.single;
    expect(sent.frameId, kitchen.id);
    expect(sent.recipe.people, 5);
    expect(directory.payloads.single, {
      'householdId': Fixtures.householdId,
      'frameId': kitchen.id,
      'recipe': {
        'id': RecipeFixtures.bobotie.id,
        'people': 5,
        'amounts': recipeFrameShare(
          RecipeFixtures.bobotie,
          RecipeScale(people: 5, servings: RecipeFixtures.bobotie.servings),
        ).amounts,
      },
    });
    expect(find.text(PhotoFrameCopy.openingOn(kitchen.name)), findsOneWidget);
    expect(find.text(CookAlongCopy.sentBody), findsOneWidget);
  });

  group('the teaser survives', () {
    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name} at 200% text on a 360-wide phone', (
        tester,
      ) async {
        await pump(tester, brightness: brightness, scale: 2);
        await emit(tester, []);
        await scrollToScaler(tester);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(CookAlongCopy.openOnFrame));
        await tester.pumpAndSettle();
        expect(find.byType(CookAlongTeaserSheet), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.dragUntilVisible(
          find.text(CookAlongCopy.notNow),
          find.descendant(
            of: find.byType(CookAlongTeaserSheet),
            matching: find.byType(Scrollable),
          ),
          const Offset(0, -200),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
