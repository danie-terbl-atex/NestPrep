import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meals_view.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meals_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_recipe_photos.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/recipe_fixtures.dart';
import '../../../support/recipe_harness.dart';

/// The Meals tab (design-system ADR-0015): recipes or this week under one
/// header, the choice the route's; and on the week, a meal planned from a
/// recipe carries its photo and the way back into it (recipes ADR-0003 §6).
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late RecipeHarness harness;
  late FakeRecipePhotoSource photos;
  late MealPlanController plan;
  late List<MealsView> views;
  late List<String> opened;

  setUp(() {
    photos = FakeRecipePhotoSource();
    harness = RecipeHarness(photos: photos);
    plan = MealPlanController(
      mealRepository: harness.meals,
      householdClock: harness.clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    views = [];
    opened = [];
  });

  tearDown(() async {
    plan.dispose();
    await harness.close();
  });

  Future<void> pump(
    WidgetTester tester,
    MealsView view, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    MealsScreen(
      view: view,
      onSelectView: views.add,
      onSelectTab: (_) {},
      onOpenRecipe: opened.add,
    ),
    providers: [
      ...harness.providers,
      ChangeNotifierProvider<MealPlanController>.value(value: plan),
    ],
    brightness: brightness,
    textScale: scale,
  );

  final fromRecipe = Meal.named(
    id: Meal.idForRecipe('bobotie'),
    name: 'Bobotie',
    addedBy: Fixtures.samMemberId,
  ).copyWith(recipeId: 'bobotie');
  final typed = Meal.named(
    id: 'spag',
    name: 'Spaghetti',
    addedBy: Fixtures.samMemberId,
  );

  Future<void> planned(WidgetTester tester) async {
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    harness.meals
      ..emitMeals([fromRecipe, typed])
      ..emitWeek(
        WeekPlan(
          id: plan.weekStart.iso,
          slots: {'4_dinner': fromRecipe.id, '4_lunch': typed.id},
        ),
      );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the recipes, and the switch asks for the week', (
    tester,
  ) async {
    await pump(tester, MealsView.recipes);
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    await tester.pumpAndSettle();

    expect(find.text(RecipeCopy.searchLabel), findsOneWidget);
    await tester.tap(find.text(MealsCopy.thisWeek));
    expect(views, [MealsView.week]);
  });

  testWidgets('the week shows the plan, and the switch asks for recipes', (
    tester,
  ) async {
    await pump(tester, MealsView.week);
    await planned(tester);

    expect(find.text(AppCopy.mealsCopyLastWeek), findsOneWidget);
    await tester.tap(find.text(MealsCopy.recipes));
    expect(views, [MealsView.recipes]);
  });

  testWidgets('a meal planned from a recipe shows its photo and how to make '
      'it; a typed one does not', (tester) async {
    await pump(tester, MealsView.week);
    await planned(tester);
    await tester.dragUntilVisible(
      find.text('Bobotie'),
      find.byType(Scrollable).last,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text(RecipeCopy.howToMakeShort), findsOneWidget);
    expect(photos.asked, contains(RecipeFixtures.bobotie.photo!.card));

    await tester.tap(find.text(RecipeCopy.howToMakeShort));
    expect(opened, ['bobotie']);
  });

  testWidgets('renders the week in dark and at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, MealsView.week, brightness: Brightness.dark, scale: 2);
    await planned(tester);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -1500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
