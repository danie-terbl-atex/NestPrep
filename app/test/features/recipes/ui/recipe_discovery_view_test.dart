import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meals_view.dart';
import 'package:nestprep/features/meal_planning/ui/meals_screen.dart';
import 'package:nestprep/features/recipes/model/recipe_facet.dart';
import 'package:nestprep/features/recipes/model/recipe_meal_filter.dart';
import 'package:nestprep/features/recipes/model/recipe_shelf.dart';
import 'package:nestprep/features/recipes/ui/recipe_card.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/pump_screen.dart';
import '../../../support/recipe_fixtures.dart';
import '../../../support/recipe_harness.dart';

/// The Meals tab's *Recipes* (recipes ADR-0003): its four states, and a
/// question nothing answers said beside the controls that change it
/// (`FE-08`).
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late RecipeHarness harness;
  late List<String> opened;
  late List<String?> heroTags;

  setUp(() {
    harness = RecipeHarness();
    opened = [];
    heroTags = [];
  });

  tearDown(() => harness.close());

  /// An ordinary phone, so the page is laid out as people see it.
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    MealsScreen(
      view: MealsView.recipes,
      onSelectView: (_) {},
      onSelectTab: (_) {},
      onPickRecipe: (_, _) async => null,
      onOpenRecipe: (id, {heroTag}) {
        opened.add(id);
        heroTags.add(heroTag);
      },
    ),
    providers: harness.providers,
    brightness: brightness,
    textScale: scale,
  );

  Future<void> deliver(WidgetTester tester) async {
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while the catalogue loads', (tester) async {
    phone(tester);
    await pump(tester);
    await tester.pump();
    expect(find.bySemanticsLabel(AppCopy.loading), findsWidgets);
    expect(find.text(MealsCopy.recipes), findsOneWidget);
  });

  testWidgets('says so in human words, with a retry, when the read fails', (
    tester,
  ) async {
    phone(tester);
    await pump(tester);
    harness.recipes.failCatalogueWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    await tester.tap(find.text(AppCopy.retry));
    // Back to the held layout, which pulses until the catalogue answers.
    await tester.pump();
    expect(harness.recipes.catalogueListens, 2);
    expect(find.bySemanticsLabel(AppCopy.loading), findsWidgets);
  });

  testWidgets('an empty catalogue says the recipes are on their way', (
    tester,
  ) async {
    phone(tester);
    await pump(tester);
    harness.recipes.emitCatalogue(const []);
    await tester.pumpAndSettle();

    expect(find.text(RecipeCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('opens on tonight’s dinner, the shelves and every recipe', (
    tester,
  ) async {
    phone(tester);
    await pump(tester);
    await deliver(tester);

    expect(find.text(RecipeCopy.tonightEyebrow.toUpperCase()), findsOneWidget);
    expect(find.text(RecipeCopy.tonightAction), findsOneWidget);
    for (final heading in [
      RecipeCopy.shelf(RecipeShelfKind.braaiDay),
      RecipeCopy.allRecipes,
    ]) {
      await tester.dragUntilVisible(
        find.text(heading),
        find.byType(CustomScrollView),
        const Offset(0, -200),
      );
      expect(find.text(heading), findsOneWidget);
    }
  });

  testWidgets('tapping tonight’s card opens that recipe from its photo', (
    tester,
  ) async {
    phone(tester);
    await pump(tester);
    await deliver(tester);

    await tester.tap(find.text(RecipeCopy.tonightAction));
    final tonight = harness.catalogue.discovery!.tonight!.id;
    expect(opened, [tonight]);
    expect(heroTags, [RecipeCard.heroTagFor('tonight', tonight)]);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == heroTags.single,
      ),
      findsOneWidget,
    );
  });

  testWidgets('every recipe photo on the list has a hero of its own', (
    tester,
  ) async {
    phone(tester);
    await pump(tester);
    await deliver(tester);

    final tags = tester
        .widgetList<Hero>(find.byType(Hero, skipOffstage: false))
        .map((hero) => hero.tag)
        .toList();
    expect(tags, isNotEmpty);
    expect(tags.toSet(), hasLength(tags.length));
  });

  testWidgets('a meal chip narrows the recipes to that meal', (tester) async {
    phone(tester);
    await pump(tester);
    await deliver(tester);

    await tester.tap(find.text(RecipeCopy.meal(RecipeMealFilter.breakfast)));
    await tester.pumpAndSettle();

    expect(find.text(RecipeCopy.matchCount(1)), findsOneWidget);
    expect(find.text(RecipeFixtures.mabele.name), findsOneWidget);
    expect(find.text(RecipeCopy.tonightAction), findsNothing);
  });

  testWidgets('nothing matching is said under the search, which stays', (
    tester,
  ) async {
    phone(tester);
    await pump(tester);
    await deliver(tester);

    await tester.enterText(find.byType(TextField), 'sushi');
    await tester.pumpAndSettle();

    expect(find.text(RecipeCopy.noMatchesTitle), findsOneWidget);
    expect(
      find.byType(TextField),
      findsOneWidget,
      reason: 'the empty state never replaces the control that fills it',
    );
    expect(find.text(RecipeCopy.meal(RecipeMealFilter.dinner)), findsOneWidget);

    // Under the Food switch, the way out sits below the fold on a small
    // phone (design-system ADR-0017).
    await tester.ensureVisible(find.text(RecipeCopy.showEverything));
    await tester.pumpAndSettle();
    await tester.tap(find.text(RecipeCopy.showEverything));
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.tonightAction), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
      reason: 'the field says the search is gone too',
    );
  });

  testWidgets('a facet chip toggles', (tester) async {
    phone(tester);
    await pump(tester);
    await deliver(tester);

    final braai = find.text(RecipeCopy.facet(RecipeFacet.braai));
    await tester.tap(braai);
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.matchCount(3)), findsOneWidget);

    await tester.tap(braai);
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.tonightAction), findsOneWidget);
  });

  testWidgets('renders in dark and at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await deliver(tester);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -1500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
