import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/features/recipes/ui/recipe_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/recipe_fixtures.dart';
import '../../../support/recipe_harness.dart';

/// A recipe's page (recipes ADR-0003): the people scaler and what it does
/// to every amount, ticking off while cooking, and adding it to the week —
/// for somebody who may plan meals, once per tap.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late RecipeHarness harness;
  var backs = 0;

  setUp(() {
    harness = RecipeHarness();
    backs = 0;
  });

  tearDown(() => harness.close());

  void phone(WidgetTester tester, {double width = 390}) {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> pump(
    WidgetTester tester, {
    String recipeId = 'bobotie',
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    phone(tester, width: scale > 1 ? 360 : 390);
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
          recipeId: recipeId,
          familySize: 4,
        ),
        update: (_, catalogue, page) => page!..followCatalogue(catalogue),
        child: RecipeScreen(onBack: () => backs++),
      ),
      providers: harness.providers,
      view: view,
      brightness: brightness,
      textScale: scale,
    );
    harness.recipes.emitCatalogue([
      ...RecipeFixtures.catalogue,
      RecipeFixtures.hakeTraybake,
    ]);
    await tester.pumpAndSettle();
  }

  Finder pageList() => find.byType(Scrollable).first;

  /// Brings [target] on screen, then to the upper part of it — clear of
  /// the floating *Add to this week* in the bottom corner.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.dragUntilVisible(target, pageList(), const Offset(0, -250));
    await tester.pumpAndSettle();
    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final y = tester.getCenter(target.first).dy;
    if (y > height * 0.4) {
      await tester.drag(pageList(), Offset(0, height * 0.4 - y));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('says what it is, what is in it that matters, and its story', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Bobotie'), findsOneWidget);
    expect(find.text(RecipeCopy.minutes(80)), findsOneWidget);
    expect(
      find.text(RecipeCopy.difficulty(RecipeFixtures.bobotie.difficulty!)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        '${RecipeCopy.energyLabel}: ${RecipeCopy.kcalSpoken(600)}',
      ),
      findsOneWidget,
      reason: 'the estimate is said to be one, not read out as a symbol',
    );
    expect(find.text(RecipeCopy.dietHeader.toUpperCase()), findsNothing);
    await scrollTo(tester, find.text(RecipeCopy.aboutHeader));
    expect(
      find.bySemanticsLabel(RegExp('^Contains milk, egg')),
      findsOneWidget,
      reason: 'allergens are said in words, not only shown as tags',
    );
  });

  testWidgets('says which ways of eating it suits (recipes ADR-0006)', (
    tester,
  ) async {
    await pump(tester, recipeId: RecipeFixtures.hakeTraybake.id);

    expect(find.text(RecipeCopy.kcal(420)), findsOneWidget);
    await scrollTo(tester, find.text(RecipeCopy.dietHeader.toUpperCase()));
    for (final diet in ['Pescatarian', 'Gluten-free', 'Dairy-free']) {
      expect(find.text(diet), findsOneWidget);
    }
  });

  testWidgets('the scaler starts at the family and moves every amount', (
    tester,
  ) async {
    await pump(tester);
    await scrollTo(tester, find.text(RecipeCopy.cookingFor.toUpperCase()));

    expect(
      find.bySemanticsLabel(RecipeCopy.cookingForLabel(4)),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RecipeCopy.scaleLabel('2/3')), findsOneWidget);
    expect(find.textContaining('665 g'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RecipeCopy.addPerson));
    await tester.tap(find.bySemanticsLabel(RecipeCopy.addPerson));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RecipeCopy.cookingForLabel(6)),
      findsOneWidget,
    );
    expect(find.text(RecipeCopy.asWritten), findsOneWidget);
    expect(find.textContaining('1 kg'), findsOneWidget);
    expect(
      find.text(RecipeCopy.resetTo(6)),
      findsNothing,
      reason: 'nothing to reset to at the recipe as written',
    );

    await tester.tap(find.bySemanticsLabel(RecipeCopy.removePerson));
    await tester.pumpAndSettle();
    await tester.tap(find.text(RecipeCopy.resetTo(6)));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RecipeCopy.cookingForLabel(6)),
      findsOneWidget,
    );
  });

  testWidgets('a line with no amount reads as it is, and never scales', (
    tester,
  ) async {
    await pump(tester);
    await scrollTo(
      tester,
      find.text(RecipeCopy.unmeasured('Salt', 'to taste')),
    );
    expect(
      find.text(RecipeCopy.unmeasured('Salt', 'to taste')),
      findsOneWidget,
    );
  });

  testWidgets('an ingredient and a step tick off while cooking', (
    tester,
  ) async {
    await pump(tester);
    final eggs = find.bySemanticsLabel(RegExp('^1 1/2 Eggs'));
    await scrollTo(tester, find.byKey(const ValueKey('ingredient-7')));
    await tester.tap(eggs);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(eggs),
      matchesSemantics(
        label: RecipeCopy.ingredientLabel('1 1/2', 'Eggs'),
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );

    final step = find.bySemanticsLabel(RegExp('^Step 2'));
    await scrollTo(tester, find.text(RecipeFixtures.bobotie.steps[1]));
    await tester.tap(step);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(step),
      matchesSemantics(
        label: RecipeCopy.stepLabel(2, RecipeFixtures.bobotie.steps[1]),
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('adds the recipe to the week at the chosen scale', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text(RecipeCopy.addToWeek));
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.forPeople(4)), findsOneWidget);
    expect(
      find.text(RecipeCopy.addTo('Thursday', AppCopy.mealsDinner)),
      findsOneWidget,
      reason: 'today and the meal the recipe is for, chosen already',
    );

    await tester.tap(find.text(AppCopy.mealsLunch));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(RecipeCopy.addTo('Thursday', AppCopy.mealsLunch)),
    );
    await tester.pumpAndSettle();

    final meal = harness.meals.recipeMeals.single;
    expect(meal.recipeId, 'bobotie');
    expect(
      meal.ingredients.firstWhere((line) => line.name == 'Beef mince').amount,
      665,
    );
    expect(harness.meals.writtenSlots.single.slots, {
      '4_lunch': Meal.idForRecipe('bobotie'),
    });
    expect(
      find.text(RecipeCopy.added('Bobotie', 'Thursday', AppCopy.mealsLunch)),
      findsOneWidget,
    );
  });

  testWidgets('cannot be added twice while the first is on its way', (
    tester,
  ) async {
    await pump(tester);
    final hold = harness.meals.holdRecipeMeal = Completer<void>();

    await tester.tap(find.text(RecipeCopy.addToWeek));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(RecipeCopy.addTo('Thursday', AppCopy.mealsDinner)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester
          .widget<NestButton>(
            find.widgetWithText(NestButton, RecipeCopy.addToWeek),
          )
          .isLoading,
      isTrue,
    );
    await tester.tap(find.text(RecipeCopy.addToWeek), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(RecipeCopy.addSheetTitle),
      findsNothing,
      reason: 'the button is busy, so no second sheet opens',
    );

    hold.complete();
    await tester.pumpAndSettle();
    expect(harness.meals.recipeMeals, hasLength(1));
  });

  testWidgets('a refused add says so in words', (tester) async {
    await pump(tester);
    harness.meals.failWritesWith = const PermissionDeniedFailure();

    await tester.tap(find.text(RecipeCopy.addToWeek));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(RecipeCopy.addTo('Thursday', AppCopy.mealsDinner)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
  });

  testWidgets('somebody who may only look at meals is not offered the add', (
    tester,
  ) async {
    await pump(
      tester,
      view: Fixtures.helperView(
        AccessGrant({HouseholdArea.meals: AccessLevel.view}),
      ),
    );
    expect(find.text('Bobotie'), findsOneWidget);
    expect(find.text(RecipeCopy.addToWeek), findsNothing);
  });

  testWidgets('a recipe that is not there says so, with the way back', (
    tester,
  ) async {
    await pump(tester, recipeId: 'retired');
    expect(find.text(RecipeCopy.missingTitle), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(AppCopy.back));
    expect(backs, 1);
  });

  for (final recipe in [RecipeFixtures.bobotie, RecipeFixtures.hakeTraybake]) {
    testWidgets(
      '${recipe.name} renders in dark and at 200% text on a 360-wide phone',
      (tester) async {
        await pump(
          tester,
          recipeId: recipe.id,
          brightness: Brightness.dark,
          scale: 2,
        );
        for (var page = 0; page < 12; page++) {
          await tester.drag(pageList(), const Offset(0, -500));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
