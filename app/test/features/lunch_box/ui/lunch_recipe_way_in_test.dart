import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_library_row.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/features/recipes/data/recipe_repository.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/fake_recipe_repository.dart';
import '../../../support/fake_starter_boxes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/test_flags.dart';

/// *How to make it* from the lunch box (lunch-box ADR-0021 §8): a packed item
/// made from a recipe — the household's own or NestPrep's — shows a button of
/// its own beside the compartment, whose tap is still the swap; the library
/// row shows one too. Anybody who may see lunches may read a recipe.
void main() {
  final dish = LunchItem.named(
    id: 'dish',
    name: 'Mexican wholewheat wrap',
    slot: LunchSlot.main,
    allergens: const {Allergen.wheat, Allergen.sesame},
    addedBy: Fixtures.samMemberId,
    householdRecipeId: StarterBoxFixtures.wrapId,
  );
  final muffin = LunchFixtures.muffin.copyWith(
    recipeId: StarterBoxFixtures.muffinId,
  );

  late LunchHarness harness;
  late FeatureFlagsController flags;
  late FakeRecipeRepository recipes;

  setUp(() {
    harness = LunchHarness();
    flags = testFlagsController(TestFlags.off);
    recipes = FakeRecipeRepository([
      StarterBoxFixtures.wrap,
      StarterBoxFixtures.muffin,
    ]);
  });
  tearDown(() async {
    flags.dispose();
    await harness.close();
  });

  Future<void> pumpBoard(WidgetTester tester, {bool canEdit = true}) async {
    tester.view.physicalSize = const Size(420 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      LunchScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<FeatureFlagsController>.value(value: flags),
        Provider<RecipeRepository>.value(value: recipes),
        ...harness.providers,
      ],
      view: canEdit
          ? null
          : Fixtures.helperView(
              AccessGrant({
                HouseholdArea.lunch: AccessLevel.view,
                HouseholdArea.familyProfiles: AccessLevel.view,
              }),
            ),
    );
    harness.emit(
      items: [...LunchFixtures.library, dish, muffin],
      plans: [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {
            for (var day = 1; day <= 5; day++) ...{
              LunchFixtures.key(day, LunchSlot.main): LunchPick.of(dish),
              LunchFixtures.key(day, LunchSlot.fruit): LunchPick.of(
                LunchFixtures.apple,
              ),
            },
          },
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  Finder howToMake(String name) => find.byTooltip(RecipeCopy.howToMake(name));

  testWidgets(
    'a packed dish opens its household recipe; an apple has no recipe',
    (tester) async {
      await pumpBoard(tester);
      final button = howToMake(dish.name);
      await bringIntoView(tester, button);
      expect(howToMake(LunchFixtures.apple.name), findsNothing);

      await tester.tap(button.first);
      await tester.pumpAndSettle();
      expect(
        recipes.linked.last,
        const HouseholdRecipeLink('test-hummus-wrap'),
      );
      expect(find.text(RecipeCopy.ingredientsHeader), findsOneWidget);
      expect(find.text('Spread, fill, roll.'), findsOneWidget);
    },
  );

  testWidgets('the compartment’s own tap is still the swap', (tester) async {
    await pumpBoard(tester);
    await bringIntoView(tester, howToMake(dish.name));
    await tester.tap(find.text(dish.name).first);
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.ingredientsHeader), findsNothing);
    expect(recipes.linked, isEmpty);
  });

  testWidgets('somebody who may only look still reads the recipe', (
    tester,
  ) async {
    await pumpBoard(tester, canEdit: false);
    await bringIntoView(tester, howToMake(dish.name));
    await tester.tap(howToMake(dish.name).first);
    await tester.pumpAndSettle();
    expect(find.text(RecipeCopy.stepsHeader), findsOneWidget);
  });

  group('the library row', () {
    Future<void> pumpRow(
      WidgetTester tester,
      LunchItem item, {
      Brightness brightness = Brightness.light,
      double textScale = 1,
    }) => pumpScreen(
      tester,
      Scaffold(
        body: ListView(children: [LunchLibraryRow(item: item, canEdit: true)]),
      ),
      providers: [Provider<RecipeRepository>.value(value: recipes)],
      brightness: brightness,
      textScale: textScale,
    );

    testWidgets('a catalogue recipe’s item opens that recipe', (tester) async {
      await pumpRow(tester, muffin);
      await tester.tap(find.text(RecipeCopy.howToMakeShort));
      await tester.pumpAndSettle();
      expect(
        recipes.linked.single,
        const CatalogueRecipeLink(StarterBoxFixtures.muffinId),
      );
      expect(find.text(RecipeCopy.ingredientsHeader), findsOneWidget);
    });

    testWidgets('an item without a recipe shows no way in', (tester) async {
      await pumpRow(tester, LunchFixtures.apple);
      expect(find.text(RecipeCopy.howToMakeShort), findsNothing);
    });

    testWidgets('fits a 360-wide phone in dark at 200% text', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpRow(tester, muffin, brightness: Brightness.dark, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text(RecipeCopy.howToMakeShort), findsOneWidget);
    });
  });
}
