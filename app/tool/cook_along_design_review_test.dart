import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_directory.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_repository.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';
import 'package:nestprep/features/photo_frames/state/frame_availability.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/features/recipes/ui/recipe_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cook_along_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_photo_frames.dart';
import '../test/support/fake_recipe_photos.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/recipe_fixtures.dart';
import '../test/support/recipe_harness.dart';
import 'review_press.dart';

/// Not a test — the cook-along press: the recipe page's way onto a frame,
/// the teaser a household without one sees, and *Show on frame* for a
/// recipe. Regenerate with
///
///     flutter test tool/cook_along_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final kitchen = FrameFixtures.frame(panels: const FramePanels(share: true));
  final hall = FrameFixtures.frame(
    id: 'frame-hall',
    name: 'Hall frame',
    panels: const FramePanels(share: true),
    accepts: PhotoFrame.pageOnly,
  );

  Future<void> press(
    WidgetTester tester,
    String name, {
    required List<PhotoFrame> frames,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Future<void> Function(FakePhotoFrameRepository repository)? act,
  }) async {
    final harness = RecipeHarness(photos: FakeRecipePhotoSource.fixture());
    final repository = FakePhotoFrameRepository();
    addTearDown(() async {
      await harness.close();
      await repository.close();
    });
    await captureScreen(
      tester,
      '$name-${brightness.name}',
      brightness: brightness,
      textScale: textScale,
      screen:
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
                    photoFrameRepository: repository,
                    householdId: Fixtures.householdId,
                    isFamily: context
                        .read<HouseholdView>()
                        .permissions
                        .isFamily,
                  ),
                  update: (_, flags, availability) => availability!
                    ..followFlag(framesOn: flags.isOn(FeatureFlag.photoFrames)),
                  child: RecipeScreen(onBack: () {}),
                ),
          ),
      providers: [
        ...harness.providers,
        Provider<PhotoFrameRepository>.value(value: repository),
        Provider<PhotoFrameDirectory>.value(value: FakePhotoFrameDirectory()),
      ],
      emit: () async {
        harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
        await tester.pumpAndSettle();
        repository.emit(frames);
        await tester.pumpAndSettle();
        final scaler = find.text(RecipeCopy.cookingFor.toUpperCase());
        await tester.dragUntilVisible(
          scaler,
          screenList(),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          screenList(),
          Offset(0, reviewPhone.height * 0.2 - tester.getCenter(scaler).dy),
        );
      },
      act: act == null ? null : () => act(repository),
    );
  }

  Future<void> openTeaser(WidgetTester tester) async {
    await tester.tap(find.text(CookAlongCopy.openOnFrame));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('the teaser on the recipe page, ${brightness.name}', (
      tester,
    ) async {
      await press(
        tester,
        'cook-along-teaser-button',
        frames: const [],
        brightness: brightness,
      );
    });

    testWidgets('the teaser sheet, ${brightness.name}', (tester) async {
      await press(
        tester,
        'cook-along-teaser-sheet',
        frames: const [],
        brightness: brightness,
        act: (_) => openTeaser(tester),
      );
    });

    testWidgets('open on frame, ${brightness.name}', (tester) async {
      await press(
        tester,
        'cook-along-button',
        frames: [kitchen],
        brightness: brightness,
      );
    });
  }

  testWidgets('the teaser sheet, dark at 200% text', (tester) async {
    await press(
      tester,
      'cook-along-teaser-sheet-200-percent-text',
      frames: const [],
      brightness: Brightness.dark,
      textScale: 2,
      act: (_) => openTeaser(tester),
    );
  });

  for (final (name, frames) in [
    ('cook-along-show-on-frame', [kitchen]),
    ('cook-along-show-on-frame-needs-update', [hall, kitchen]),
    ('cook-along-show-on-frame-only-needs-update', [hall]),
  ]) {
    testWidgets('$name, light', (tester) async {
      await press(
        tester,
        name,
        frames: frames,
        act: (repository) async {
          await tester.tap(find.text(CookAlongCopy.openOnFrame));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          repository.emit(frames);
        },
      );
    });
  }
}
