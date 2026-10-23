import 'package:go_router/go_router.dart';

import '../features/meal_planning/model/meals_view.dart';
import 'household_route.dart';
import 'household_shell.dart';

/// Where the Meals tab lives in the route table (design-system ADR-0015):
/// the tab, with its view in the `view` query — the recipes unless it says
/// `week` — and a recipe's own page under it (recipes ADR-0003). Every one
/// is deep-linkable (`FE-17`).
abstract final class MealsRoute {
  static const viewQuery = 'view';
  static const recipesSegment = 'recipes';
  static const recipeParameter = 'recipeId';

  static final path = '${HouseholdRoute.path}/${HouseholdTab.meals.segment}';
  static final recipePath = '$path/$recipesSegment/:$recipeParameter';

  /// The tab on [view]; the recipes, its default, carry no query.
  static String pathFor(
    String householdId, {
    MealsView view = MealsView.recipes,
  }) => Uri(
    path: HouseholdRoute.pathFor(householdId, HouseholdTab.meals),
    queryParameters: view == MealsView.recipes ? null : {viewQuery: view.name},
  ).toString();

  static String recipePathFor(String householdId, String recipeId) =>
      '${HouseholdRoute.pathFor(householdId, HouseholdTab.meals)}'
      '/$recipesSegment/${Uri.encodeComponent(recipeId)}';

  static MealsView viewFrom(GoRouterState state) =>
      MealsView.fromQuery(state.uri.queryParameters[viewQuery]);

  /// The recipe this page was matched with. Its absence would mean the
  /// route table and this helper disagree, which is our bug.
  static String recipeIdFrom(GoRouterState state) {
    final id = state.pathParameters[recipeParameter];
    if (id == null || id.isEmpty) {
      throw StateError('a recipe route matched without a $recipeParameter');
    }
    return id;
  }
}
