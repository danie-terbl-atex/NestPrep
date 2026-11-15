import 'package:go_router/go_router.dart';

import '../features/meal_planning/model/meals_view.dart';
import '../features/meal_planning/model/week_plan.dart';
import '../features/recipes/model/recipe_import_way.dart';
import '../shared/time/calendar_date.dart';
import 'household_route.dart';
import 'household_shell.dart';

/// Where the Meals tab lives in the route table (design-system ADR-0015):
/// the tab, with its view in the `view` query, and a recipe's own page under
/// it (recipes ADR-0003). Every one is deep-linkable (`FE-17`).
abstract final class MealsRoute {
  static const viewQuery = 'view';
  static const recipesSegment = 'recipes';
  static const recipeParameter = 'recipeId';
  static const pickSegment = 'pick';
  static const newSegment = 'new';
  static const editSegment = 'edit';
  static const importSegment = 'import';
  static const importPdfSegment = 'import-pdf';
  static const wayQuery = 'way';
  static const slotQuery = 'slot';
  static const dayQuery = 'day';

  static final path = '${HouseholdRoute.path}/${HouseholdTab.meals.segment}';
  static final recipePath = '$path/$recipesSegment/:$recipeParameter';
  static final pickPath = '$path/$pickSegment';
  static final newRecipePath = '$path/$recipesSegment/$newSegment';
  static final editRecipePath = '$recipePath/$editSegment';
  static final importRecipePath = '$path/$recipesSegment/$importSegment';
  static final importPdfPath = '$path/$recipesSegment/$importPdfSegment';

  /// The tab on [view]; with none, on the view the household opens on.
  static String pathFor(String householdId, {MealsView? view}) => Uri(
    path: HouseholdRoute.pathFor(householdId, HouseholdTab.meals),
    queryParameters: view == null ? null : {viewQuery: view.name},
  ).toString();

  static String recipePathFor(String householdId, String recipeId) =>
      '${HouseholdRoute.pathFor(householdId, HouseholdTab.meals)}'
      '/$recipesSegment/${Uri.encodeComponent(recipeId)}';

  static String newRecipePathFor(String householdId) =>
      '${HouseholdRoute.pathFor(householdId, HouseholdTab.meals)}'
      '/$recipesSegment/$newSegment';

  static String importRecipePathFor(String householdId, RecipeImportWay way) =>
      Uri(
        path:
            '${HouseholdRoute.pathFor(householdId, HouseholdTab.meals)}'
            '/$recipesSegment/$importSegment',
        queryParameters: {wayQuery: way.name},
      ).toString();

  static String importPdfPathFor(String householdId) =>
      '${HouseholdRoute.pathFor(householdId, HouseholdTab.meals)}'
      '/$recipesSegment/$importPdfSegment';

  static RecipeImportWay importWayFrom(GoRouterState state) =>
      RecipeImportWay.fromQuery(state.uri.queryParameters[wayQuery]);

  static String editRecipePathFor(String householdId, String recipeId) =>
      '${recipePathFor(householdId, recipeId)}/$editSegment';

  static String pickPathFor(
    String householdId, {
    required MealSlot slot,
    required CalendarDate day,
  }) => Uri(
    path:
        '${HouseholdRoute.pathFor(householdId, HouseholdTab.meals)}'
        '/$pickSegment',
    queryParameters: {slotQuery: slot.name, dayQuery: day.iso},
  ).toString();

  static MealSlot? slotFrom(GoRouterState state) => MealSlot.values
      .where((slot) => slot.name == state.uri.queryParameters[slotQuery])
      .firstOrNull;

  static CalendarDate? dayFrom(GoRouterState state) {
    final iso = state.uri.queryParameters[dayQuery];
    if (iso == null) return null;
    try {
      return CalendarDate.parse(iso);
    } on FormatException {
      return null;
    }
  }

  static MealsView? viewFrom(GoRouterState state) =>
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
