import 'package:nestprep/features/meal_planning/data/meal_repository.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_source.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_meal_repository.dart';
import 'fake_recipe_photos.dart';
import 'fake_recipe_repository.dart';

/// What the Meals tab's shell gives every screen under it (recipes
/// ADR-0003): the catalogue's one listener over a fake repository, the
/// pictures, and the meals a recipe is planned into.
final class RecipeHarness {
  RecipeHarness({RecipePhotoSource? photos})
    : photos = photos ?? FakeRecipePhotoSource();

  final recipes = FakeRecipeRepository();
  final meals = FakeMealRepository();
  final RecipePhotoSource photos;

  /// Thursday 22 October 2026, mid-morning in Johannesburg.
  static final nowUtc = DateTime.utc(2026, 10, 22, 8);
  final clock = HouseholdClock('Africa/Johannesburg', now: () => nowUtc);

  late final catalogue = RecipeCatalogueController(
    recipeRepository: recipes,
    householdClock: clock,
  );

  List<SingleChildWidget> get providers => [
    Provider<HouseholdClock>.value(value: clock),
    Provider<RecipePhotoSource>.value(value: photos),
    Provider<MealRepository>.value(value: meals),
    ChangeNotifierProvider<RecipeCatalogueController>.value(value: catalogue),
  ];

  Future<void> close() async {
    catalogue.dispose();
    await recipes.close();
    await meals.close();
  }
}
