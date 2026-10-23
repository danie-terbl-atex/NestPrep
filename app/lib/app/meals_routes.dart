import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/meal_planning/state/meal_plan_controller.dart';
import '../features/meal_planning/ui/meals_screen.dart';
import '../features/recipes/data/recipe_repository.dart';
import '../features/recipes/model/family_size.dart';
import '../features/recipes/state/recipe_catalogue_controller.dart';
import '../features/recipes/state/recipe_page_controller.dart';
import '../features/recipes/ui/recipe_screen.dart';
import '../shared/time/household_clock.dart';
import 'household_route.dart';
import 'household_tab_navigation.dart';
import 'meals_route.dart';
import 'viewer_member.dart';

/// The Meals tab's routes under the household shell (design-system
/// ADR-0015, recipes ADR-0003), in their own file so the route table gains
/// one line.
///
/// The catalogue is read once for the whole tab: the recipes view, a
/// recipe's page and the week's recipe-linked meals all read this one
/// listener (foundation ADR-0006), and a recipe opened over the list comes
/// back to it as it was left.
ShellRoute mealsRoutes() => ShellRoute(
  builder: (context, state, child) => ChangeNotifierProvider(
    create: (context) => RecipeCatalogueController(
      recipeRepository: context.read<RecipeRepository>(),
      householdClock: context.read<HouseholdClock>(),
    ),
    child: child,
  ),
  routes: [
    GoRoute(
      path: MealsRoute.path,
      builder: (context, state) {
        final householdId = HouseholdRoute.idFrom(state);
        return ChangeNotifierProvider(
          create: (context) => MealPlanController(
            mealRepository: context.read<MealRepository>(),
            householdClock: context.read<HouseholdClock>(),
            householdId: householdId,
            memberId: viewerMemberIdOf(context),
          ),
          child: MealsScreen(
            view: MealsRoute.viewFrom(state),
            // A view is a place on the tab, not a step into it: switching
            // replaces rather than stacks, so back leaves the tab.
            onSelectView: (view) =>
                context.go(MealsRoute.pathFor(householdId, view: view)),
            onSelectTab: (tab) => goToTab(context, state, tab),
            onOpenRecipe: (recipeId) =>
                context.push(MealsRoute.recipePathFor(householdId, recipeId)),
          ),
        );
      },
    ),
    GoRoute(
      path: MealsRoute.recipePath,
      builder: (context, state) {
        final householdId = HouseholdRoute.idFrom(state);
        return ChangeNotifierProxyProvider<
          RecipeCatalogueController,
          RecipePageController
        >(
          create: (context) => RecipePageController(
            mealRepository: context.read<MealRepository>(),
            householdId: householdId,
            memberId: viewerMemberIdOf(context),
            recipeId: MealsRoute.recipeIdFrom(state),
            familySize: familySizeOf(context.read<HouseholdView>()),
          ),
          update: (context, catalogue, page) =>
              page!..followCatalogue(catalogue),
          child: RecipeScreen(
            // A link straight here has nothing under it: back is the
            // recipes, never out of the app.
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(MealsRoute.pathFor(householdId)),
          ),
        );
      },
    ),
  ],
);
