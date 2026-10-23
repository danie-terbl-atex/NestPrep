import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_checkers/data/checkers_area_preference.dart';
import '../features/add_to_checkers/data/checkers_directory.dart';
import '../features/add_to_checkers/data/checkers_place_resolver.dart';
import '../features/add_to_checkers/data/product_match_ranker.dart';
import '../features/add_to_checkers/data/retailer_catalogues.dart';
import '../features/add_to_checkers/data/retailer_preference.dart';
import '../features/add_to_checkers/model/retailer_switch.dart';
import '../features/add_to_checkers/state/cart_push_controller.dart';
import '../features/add_to_checkers/state/product_match_controller.dart';
import '../features/add_to_checkers/state/retailer_choice_controller.dart';
import '../features/add_to_checkers/state/shop_carts.dart';
import '../features/add_to_pnp/data/pnp_directory.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/groceries/data/grocery_suggestion_source.dart';
import '../features/groceries/data/lunch_plan_grocery_source.dart';
import '../features/groceries/data/meal_plan_grocery_source.dart';
import '../features/groceries/state/grocery_list_controller.dart';
import '../features/groceries/state/grocery_plan_controller.dart';
import '../features/groceries/ui/grocery_list_screen.dart';
import '../features/groceries/ui/grocery_plan_wording.dart';
import '../features/home_care/data/home_care_library_repository.dart';
import '../features/home_care/data/home_care_stock_grocery_source.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/live_location/data/location_source.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/data/lunch_week_reader.dart';
import '../features/lunch_box/model/lunch_week.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/meal_planning/model/meals_view.dart';
import '../features/recipes/data/recipe_repository.dart';
import '../shared/flags/feature_flags_controller.dart';
import '../shared/time/household_clock.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'household_tab_navigation.dart';
import 'meals_route.dart';
import 'viewer_member.dart';

/// Everything that may put things on the grocery list (groceries ADR-0004).
///
/// **Plugging a source in is one line here.** Home-care's product stock
/// tracker adds its `GrocerySuggestionSource` to this list; the groceries
/// feature reads it for whoever may see its area, merges, dedups, proposes and
/// keeps in step exactly as it does the plans.
List<GrocerySuggestionSource> groceryPlanSources(BuildContext context) => [
  MealPlanGrocerySource(context.read<MealRepository>()),
  LunchPlanGrocerySource(
    LunchWeekReader(context.read<LunchRepository>()),
    context.read<RecipeRepository>(),
  ),
  // home-care V2: products running low (home-care ADR-0005).
  HomeCareStockGrocerySource(context.read<HomeCareLibraryRepository>()),
];

/// The grocery tab (groceries ADR-0002): the list, and beside it the week's
/// plans against the list — one controller each, both living as long as the
/// screen does (foundation ADR-0006).
GoRoute groceryRoute() => GoRoute(
  path: '${HouseholdRoute.path}/${HouseholdTab.groceries.segment}',
  builder: (context, state) {
    final householdId = HouseholdRoute.idFrom(state);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => GroceryListController(
            groceryRepository: context.read<GroceryRepository>(),
            householdId: householdId,
            memberId: viewerMemberIdOf(context),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => _planController(context, householdId),
        ),
        // Product matches and the carts, at Checkers and Pick n Pay (the
        // Checkers build contract, add-to-pnp ADR-0007). Created whatever the
        // switches say — none does anything until the screen, which reads
        // them, asks.
        ChangeNotifierProvider(
          create: (context) => ProductMatchController(
            catalogues: context.read<RetailerCatalogues>(),
            placeResolver: CheckersPlaceResolver(
              locationSource: context.read<LocationSource>(),
              areaPreference: context.read<CheckersAreaPreference>(),
            ),
            groceryRepository: context.read<GroceryRepository>(),
            householdId: householdId,
            memberId: viewerMemberIdOf(context),
            ranker: context.read<ProductMatchRanker>(),
          ),
        ),
        // The shop *Find at* asks, among those switched on.
        ChangeNotifierProvider(
          create: (context) {
            final flags = context.read<FeatureFlagsController>();
            return RetailerChoiceController(
              preference: context.read<RetailerPreference>(),
              householdId: householdId,
              shopsOn: () => shopsOn(flags.isOn),
            );
          },
        ),
        Provider(
          create: (context) => ShopCarts(
            checkers: CartPushController(
              directory: context.read<CheckersDirectory>(),
              householdId: householdId,
            ),
            pickNPay: CartPushController(
              directory: context.read<PnpDirectory>(),
              householdId: householdId,
            ),
          ),
          dispose: (context, carts) => carts.dispose(),
        ),
      ],
      child: GroceryListScreen(
        // The list's "from the meal plan" opens the plan itself — the Meals
        // tab's week, not its recipes (design-system ADR-0015).
        onSelectTab: (tab) => tab == HouseholdTab.meals
            ? context.go(MealsRoute.pathFor(householdId, view: MealsView.week))
            : goToTab(context, state, tab),
      ),
    );
  },
);

GroceryPlanController _planController(
  BuildContext context,
  String householdId,
) {
  final household = context.read<HouseholdView>();
  final permissions = household.permissions;
  final sources = groceryPlanSources(context);
  final visible = [
    for (final source in sources)
      if (permissions.canView(source.area)) source,
  ];
  final canEdit = permissions.canEdit(HouseholdArea.groceries);
  return GroceryPlanController(
    groceryRepository: context.read<GroceryRepository>(),
    // Somebody who only reads the list is never offered the plans, so the
    // plans are not read for them either.
    sources: canEdit ? visible : const [],
    wording: groceryPlanWording(household),
    householdId: householdId,
    memberId: viewerMemberIdOf(context),
    week: LunchWeek.planningFor(context.read<HouseholdClock>().today),
    canEdit: canEdit,
    seesEverySource: visible.length == sources.length,
  );
}
