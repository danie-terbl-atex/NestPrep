import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/add_to_checkers/data/checkers_area_preference.dart';
import '../features/add_to_checkers/data/checkers_catalogue.dart';
import '../features/add_to_checkers/data/checkers_place_resolver.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/live_location/data/location_source.dart';
import '../features/lunch_box/data/lunch_budget_repository.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/state/lunch_board_controller.dart';
import '../features/plan_week/data/lunch_aisle_source.dart';
import '../features/plan_week/data/lunch_idea_drafter.dart';
import '../features/plan_week/data/lunch_week_builder.dart';
import '../features/plan_week/data/shop_week_groceries.dart';
import '../features/plan_week/state/plan_week_controller.dart';
import '../features/plan_week/state/shop_week_saver.dart';
import '../features/plan_week/ui/plan_week_screen.dart';
import 'household_route.dart';
import 'plan_week_route.dart';
import 'viewer_member.dart';

/// *Plan my week from Checkers* under the lunch shell (lunch-box ADR-0012).
/// Made fresh on every visit, for the week the board is on, following the
/// board so every check is against the children and rules the phone holds
/// now. The shop is the same Checkers catalogue and chosen area the grocery
/// list's matches use.
GoRoute planWeekRoute() => GoRoute(
  path: PlanWeekRoute.path,
  builder: (context, state) {
    final householdId = HouseholdRoute.idFrom(state);
    final memberId = viewerMemberIdOf(context);
    return ChangeNotifierProxyProvider<
      LunchBoardController,
      PlanWeekController
    >(
      create: (context) => PlanWeekController(
        drafter: context.read<LunchIdeaDrafter>(),
        aisleSource: context.read<LunchAisleSource>(),
        weekBuilder: context.read<LunchWeekBuilder>(),
        catalogue: context.read<CheckersCatalogue>(),
        placeResolver: CheckersPlaceResolver(
          locationSource: context.read<LocationSource>(),
          areaPreference: context.read<CheckersAreaPreference>(),
        ),
        saver: ShopWeekSaver(
          lunchRepository: context.read<LunchRepository>(),
          budgetRepository: context.read<LunchBudgetRepository>(),
          householdId: householdId,
          memberId: memberId,
        ),
        groceries: ShopWeekGroceries(
          groceryRepository: context.read<GroceryRepository>(),
          householdId: householdId,
          memberId: memberId,
        ),
        householdId: householdId,
        week: context.read<LunchBoardController>().week,
      ),
      update: (context, lunch, controller) =>
          controller!..followBoard(lunch.board),
      child: const PlanWeekScreen(),
    );
  },
);
