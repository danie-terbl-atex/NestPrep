import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/recipes/data/own_recipe_repository.dart';
import 'package:nestprep/features/recipes/state/own_recipe_deleter.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/features/recipes/ui/recipe_screen.dart';
import 'package:nestprep/shared/links/external_link_opener.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_link_opener.dart';
import 'fake_own_recipes.dart';
import 'household_fixtures.dart';
import 'pump_screen.dart';
import 'recipe_harness.dart';

/// A recipe's page as its route builds it, for an own recipe.
final class OwnRecipePage {
  OwnRecipePage(this.harness);

  final RecipeHarness harness;
  final ownRecipes = FakeOwnRecipeRepository();
  final linkOpener = FakeLinkOpener();
  var edits = 0;
  var leftAfterDelete = 0;

  Future<void> pump(
    WidgetTester tester, {
    required String recipeId,
    HouseholdView? view,
    List<SingleChildWidget> providers = const [],
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
          recipeId: recipeId,
          familySize: 4,
        ),
        update: (_, catalogue, page) => page!..followCatalogue(catalogue),
        child: ChangeNotifierProvider(
          create: (_) => OwnRecipeDeleter(
            ownRecipes: ownRecipes,
            photoSource: harness.photos,
            householdId: Fixtures.householdId,
          ),
          child: RecipeScreen(
            onBack: () {},
            onEdit: () => edits++,
            onDeleted: () => leftAfterDelete++,
          ),
        ),
      ),
      providers: [
        ...harness.providers,
        Provider<OwnRecipeRepository>.value(value: ownRecipes),
        Provider<ExternalLinkOpener>.value(value: linkOpener),
        ...providers,
      ],
      view: view,
      brightness: brightness,
      textScale: scale,
    );
  }
}
