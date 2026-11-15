import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/meals_route.dart';
import 'package:nestprep/app/meals_routes.dart';
import 'package:nestprep/features/lunch_box/data/lunch_repository.dart';
import 'package:nestprep/features/meal_planning/data/meal_repository.dart';
import 'package:nestprep/features/meal_planning/model/meals_view.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/ui/meal_week_view.dart';
import 'package:nestprep/features/meal_planning/ui/meals_screen.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_source.dart';
import 'package:nestprep/features/recipes/data/recipe_repository.dart';
import 'package:nestprep/features/recipes/model/recipe_import_way.dart';
import 'package:nestprep/features/recipes/ui/recipe_builder_screen.dart';
import 'package:nestprep/features/recipes/ui/recipe_discovery_view.dart';
import 'package:nestprep/features/recipes/ui/recipe_document_screen.dart';
import 'package:nestprep/features/recipes/ui/recipe_import_screen.dart';
import 'package:nestprep/features/recipes/ui/recipe_picker_screen.dart';
import 'package:nestprep/features/recipes/ui/recipe_screen.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_lunch_repository.dart';
import '../../../support/fake_meal_repository.dart';
import '../../../support/fake_recipe_photos.dart';
import '../../../support/fake_recipe_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/premium_entitlement.dart';
import '../../../support/pump_screen.dart';

/// Recipes are Premium and the week is free (subscriptions ADR-0008): every
/// recipe address shows its place locked to a household without Premium, and
/// nothing behind it starts.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeRecipeRepository recipes;
  late FakeMealRepository meals;
  late FakeLunchRepository lunches;

  setUp(() {
    recipes = FakeRecipeRepository();
    meals = FakeMealRepository();
    lunches = FakeLunchRepository();
  });

  tearDown(() async {
    await recipes.close();
    await meals.close();
    await lunches.close();
  });

  Future<void> open(
    WidgetTester tester,
    String location, {
    List<SingleChildWidget> also = const [],
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final router = GoRouter(initialLocation: location, routes: [mealsRoutes()]);
    addTearDown(router.dispose);
    await pumpRouter(
      tester,
      router: router,
      providers: [
        Provider<RecipeRepository>.value(value: recipes),
        Provider<RecipePhotoSource>.value(value: FakeRecipePhotoSource()),
        Provider<MealRepository>.value(value: meals),
        Provider<LunchRepository>.value(value: lunches),
        ...also,
      ],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pump();
    await tester.pump();
  }

  const id = Fixtures.householdId;
  final places = {
    'a recipe': MealsRoute.recipePathFor(id, 'bobotie'),
    'picking one for a slot': MealsRoute.pickPathFor(
      id,
      slot: MealSlot.dinner,
      day: CalendarDate(2026, 10, 22),
    ),
    'adding one': MealsRoute.newRecipePathFor(id),
    'editing one': MealsRoute.editRecipePathFor(id, 'bobotie'),
    'importing from a link': MealsRoute.importRecipePathFor(
      id,
      RecipeImportWay.link,
    ),
    'importing a PDF': MealsRoute.importPdfPathFor(id),
  };

  for (final MapEntry(key: place, value: location) in places.entries) {
    testWidgets('$place is locked without Premium', (tester) async {
      await open(tester, location);

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.recipes)),
        findsOneWidget,
      );
      for (final screen in [
        RecipeScreen,
        RecipePickerScreen,
        RecipeBuilderScreen,
        RecipeImportScreen,
        RecipeDocumentScreen,
      ]) {
        expect(find.byType(screen), findsNothing);
      }
      expect(recipes.catalogueListens, 0);
      expect(recipes.ownListens, isEmpty);
    });
  }

  testWidgets('the tab opens on the week without Premium', (tester) async {
    await open(tester, MealsRoute.pathFor(id));

    expect(find.byType(MealWeekView), findsOneWidget);
    expect(recipes.catalogueListens, 0);
  });

  testWidgets('a link to the recipes shows them locked without Premium', (
    tester,
  ) async {
    await open(tester, MealsRoute.pathFor(id, view: MealsView.recipes));

    expect(find.byType(MealsScreen), findsOneWidget);
    expect(find.byType(MealWeekView), findsNothing);
    expect(find.byType(PremiumLockedView), findsOneWidget);
    expect(recipes.catalogueListens, 0);
  });

  testWidgets('with Premium the tab opens on the recipes and listens once', (
    tester,
  ) async {
    await open(
      tester,
      MealsRoute.pathFor(id),
      also: [premiumEntitlementProvider()],
    );

    expect(find.byType(RecipeDiscoveryView), findsOneWidget);
    expect(find.byType(PremiumLockedView), findsNothing);
    expect(recipes.catalogueListens, 1);
  });

  testWidgets('a locked recipe renders in dark and at 200% text on a '
      '360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await open(
      tester,
      MealsRoute.recipePathFor(id, 'bobotie'),
      brightness: Brightness.dark,
      scale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PremiumLockedView), findsOneWidget);
  });
}
