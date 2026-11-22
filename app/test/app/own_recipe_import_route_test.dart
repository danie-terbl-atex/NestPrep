import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/meals_route.dart';
import 'package:nestprep/app/own_recipe_routes.dart';
import 'package:nestprep/features/meal_planning/data/meal_repository.dart';
import 'package:nestprep/features/recipes/data/own_recipe_photo_store.dart';
import 'package:nestprep/features/recipes/data/own_recipe_repository.dart';
import 'package:nestprep/features/recipes/data/recipe_drafter.dart';
import 'package:nestprep/features/recipes/data/recipe_image_fetcher.dart';
import 'package:nestprep/features/recipes/data/recipe_page_reader.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_picker.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_source.dart';
import 'package:nestprep/features/recipes/data/recipe_snap_picker.dart';
import 'package:nestprep/features/recipes/model/recipe_draft_reading.dart';
import 'package:nestprep/features/recipes/model/recipe_import_way.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../support/fake_meal_repository.dart';
import '../support/fake_own_recipes.dart';
import '../support/fake_recipe_import.dart';
import '../support/fake_recipe_photos.dart';
import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';
import '../support/pump_subscriptions.dart';

void main() {
  const picture = 'https://cdn.example.com/bobotie.jpg';

  late FakeRecipePageReader reader;
  late FakeRecipeDrafter drafter;
  late FakeRecipeImageFetcher images;
  late FakeMealRepository meals;
  late GoRouter router;

  setUp(() {
    reader = FakeRecipePageReader();
    drafter = FakeRecipeDrafter();
    images = FakeRecipeImageFetcher(const <String, Uint8List?>{picture: null});
    meals = FakeMealRepository();
  });

  tearDown(() => meals.close());

  Future<void> pumpRoutes(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            context.watch<HouseholdEntitlement>();
            return const Scaffold(body: SizedBox.expand());
          },
        ),
        ...ownRecipeRoutes(),
      ],
    );
    addTearDown(router.dispose);
    await pumpRouter(
      tester,
      router: router,
      providers: [
        ...SubscriptionHarness(
          entitlement: Entitlement(premiumUntil: DateTime.utc(2100)),
        ).providers,
        Provider<RecipePageReader>.value(value: reader),
        Provider<RecipeDrafter>.value(value: drafter),
        Provider<RecipeImageFetcher>.value(value: images),
        Provider<RecipeSnapPicker>.value(value: FakeRecipeSnapPicker()),
        Provider<OwnRecipeRepository>.value(value: FakeOwnRecipeRepository()),
        Provider<OwnRecipePhotoStore>.value(value: FakeOwnRecipePhotoStore()),
        Provider<RecipePhotoPicker>.value(value: FakeRecipePhotoPicker()),
        Provider<RecipePhotoSource>.value(value: FakeRecipePhotoSource()),
        Provider<MealRepository>.value(value: meals),
      ],
    );
    await tester.pumpAndSettle();
  }

  String importPath(RecipeImportWay way) =>
      MealsRoute.importRecipePathFor(Fixtures.householdId, way);

  testWidgets('a shared link runs, and the builder replaces the import, filled '
      'in and asking for its pictures', (tester) async {
    drafter.reading = RecipeDraftReading(
      draft: aBobotieDraft(candidateImageUrls: const [picture]),
      callsLeft: 9,
    );
    await pumpRoutes(tester);

    unawaited(
      router.push<void>(importPath(RecipeImportWay.link), extra: aBobotieLink),
    );
    await tester.pumpAndSettle();

    expect(reader.asked, [aBobotieLink]);
    expect(find.text(OwnRecipeCopy.newTitle), findsOneWidget);
    expect(find.text('Bobotie'), findsOneWidget);
    expect(images.asked, [picture]);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text(RecipeImportCopy.linkScreenTitle), findsNothing);
  });

  testWidgets('with no link it waits on the link panel, sending nothing', (
    tester,
  ) async {
    await pumpRoutes(tester);

    unawaited(router.push<void>(importPath(RecipeImportWay.link)));
    await tester.pumpAndSettle();

    expect(find.text(RecipeImportCopy.linkScreenTitle), findsOneWidget);
    expect(reader.asked, isEmpty);
  });

  testWidgets('the snap way opens on its photo panel', (tester) async {
    await pumpRoutes(tester);

    unawaited(router.push<void>(importPath(RecipeImportWay.snap)));
    await tester.pumpAndSettle();

    expect(find.text(RecipeImportCopy.snapScreenTitle), findsOneWidget);
    expect(find.text(RecipeImportCopy.photoPrivacyBody), findsOneWidget);
  });
}
