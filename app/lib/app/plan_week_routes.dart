import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_checkers/data/checkers_area_preference.dart';
import '../features/add_to_checkers/data/checkers_place_resolver.dart';
import '../features/add_to_checkers/data/retailer_catalogues.dart';
import '../features/add_to_checkers/state/cart_push_controller.dart';
import '../features/add_to_pnp/data/pnp_directory.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/live_location/data/location_source.dart';
import '../features/lunch_box/data/lunch_budget_repository.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/state/lunch_board_controller.dart';
import '../features/lunch_box/state/lunch_variety_choice.dart';
import '../features/plan_week/data/lunch_aisle_source.dart';
import '../features/plan_week/data/lunch_idea_drafter.dart';
import '../features/plan_week/data/lunch_recipe_saver.dart';
import '../features/plan_week/data/lunch_week_builder.dart';
import '../features/plan_week/data/packing_choice_store.dart';
import '../features/plan_week/data/shop_week_groceries.dart';
import '../features/plan_week/state/lunch_shop_choice.dart';
import '../features/plan_week/state/plan_week_controller.dart';
import '../features/plan_week/state/shop_week_saver.dart';
import '../features/plan_week/ui/plan_week_screen.dart';
import '../shared/flags/feature_flag.dart';
import '../shared/flags/feature_flags_controller.dart';
import 'household_route.dart';
import 'plan_week_route.dart';
import 'viewer_member.dart';

/// *Plan my week* under the lunch shell (lunch-box ADR-0012, ADR-0026). Made
/// fresh on every visit, for the week the board is on, following the board
/// so every check is against the children and rules the phone holds now.
/// The shop is the one chosen on this phone — the shell's `LunchShopChoice`,
/// which the board's row reads too — searched near the same area the grocery
/// list's matches use. A Pick n Pay week can go straight into the member's
/// own cart, through the one cart-push flow (add-to-pnp ADR-0004).
GoRoute planWeekRoute() => GoRoute(
  path: PlanWeekRoute.path,
  builder: (context, state) {
    final householdId = HouseholdRoute.idFrom(state);
    final memberId = viewerMemberIdOf(context);
    final flags = context.read<FeatureFlagsController?>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => CartPushController(
            directory: context.read<PnpDirectory>(),
            householdId: householdId,
          ),
        ),
        ChangeNotifierProxyProvider<LunchBoardController, PlanWeekController>(
          create: (context) => PlanWeekController(
            drafter: context.read<LunchIdeaDrafter>(),
            aisleSource: context.read<LunchAisleSource>(),
            weekBuilder: context.read<LunchWeekBuilder>(),
            catalogues: context.read<RetailerCatalogues>(),
            shopChoice: context.read<LunchShopChoice>(),
            isPnpOn: () => flags?.isOn(FeatureFlag.addToPnp) ?? false,
            placeResolver: CheckersPlaceResolver(
              locationSource: context.read<LocationSource>(),
              areaPreference: context.read<CheckersAreaPreference>(),
            ),
            saver: ShopWeekSaver(
              lunchRepository: context.read<LunchRepository>(),
              budgetRepository: context.read<LunchBudgetRepository>(),
              recipeSaver: context.read<LunchRecipeSaver>(),
              householdId: householdId,
              memberId: memberId,
            ),
            groceries: ShopWeekGroceries(
              groceryRepository: context.read<GroceryRepository>(),
              householdId: householdId,
              memberId: memberId,
            ),
            packingStore: context.read<PackingChoiceStore>(),
            variety: context.read<LunchVarietyChoice>(),
            householdId: householdId,
            week: context.read<LunchBoardController>().week,
          ),
          update: (context, lunch, controller) =>
              controller!..followBoard(lunch.board),
        ),
      ],
      child: const PlanWeekScreen(),
    );
  },
);
