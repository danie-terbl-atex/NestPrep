import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/accounts/model/kid_identity.dart';
import '../features/accounts/ui/session_gate_screen.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/household/data/household_repository.dart';
import '../features/lunch_box/data/lunch_budget_repository.dart';
import '../features/lunch_box/data/lunch_choices_repository.dart';
import '../features/lunch_box/data/lunch_pantry_repository.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/state/lunch_board_controller.dart';
import '../features/lunch_box/state/lunch_budget_controller.dart';
import '../features/lunch_box/state/lunch_choices_controller.dart';
import '../features/lunch_box/state/lunch_choose_controller.dart';
import '../features/lunch_box/state/lunch_pantry_controller.dart';
import '../features/lunch_box/state/lunch_pantry_groceries.dart';
import '../features/lunch_box/ui/lunch_budget_screen.dart';
import '../features/lunch_box/ui/lunch_choose_screen.dart';
import '../features/lunch_box/ui/lunch_kid_picks_screen.dart';
import '../features/lunch_box/ui/lunch_pantry_screen.dart';
import '../features/lunch_box/ui/lunch_prices_screen.dart';
import '../shared/async/async_state.dart';
import '../shared/time/calendar_date.dart';
import '../shared/time/household_clock.dart';
import 'household_route.dart';
import 'lunch_planning_route.dart';
import 'viewer_member.dart';

/// The controllers of lunch-box's V2 tools (lunch-box ADR-0006 to ADR-0008),
/// on the lunch shell beside the board's, each following the board so it
/// reads the plans once. Lazy: a tool whose switch is off is never read.
List<SingleChildWidget> lunchPlanningShellProviders(GoRouterState state) => [
  ChangeNotifierProxyProvider<LunchBoardController, LunchPantryController>(
    create: (context) => LunchPantryController(
      pantryRepository: context.read<LunchPantryRepository>(),
      lunchRepository: context.read<LunchRepository>(),
      groceries: LunchPantryGroceries(
        groceryRepository: context.read<GroceryRepository>(),
        householdId: HouseholdRoute.idFrom(state),
        memberId: viewerMemberIdOf(context),
      ),
      householdId: HouseholdRoute.idFrom(state),
      memberId: viewerMemberIdOf(context),
    ),
    update: (context, lunch, pantry) =>
        pantry!..followBoard(lunch.board, lunch.week),
  ),
  ChangeNotifierProxyProvider<LunchBoardController, LunchBudgetController>(
    create: (context) => LunchBudgetController(
      budgetRepository: context.read<LunchBudgetRepository>(),
      householdId: HouseholdRoute.idFrom(state),
      memberId: viewerMemberIdOf(context),
    ),
    update: (context, lunch, budget) => budget!..followBoard(lunch.board),
  ),
  ChangeNotifierProxyProvider<LunchBoardController, LunchChoicesController>(
    create: (context) => LunchChoicesController(
      choicesRepository: context.read<LunchChoicesRepository>(),
      householdId: HouseholdRoute.idFrom(state),
      memberId: viewerMemberIdOf(context),
    ),
    update: (context, lunch, choices) =>
        choices!..followBoard(lunch.board, lunch.week),
  ),
];

/// The V2 tools' pages under the lunch shell.
List<RouteBase> lunchPlanningRoutes() => [
  GoRoute(
    path: LunchPlanningRoute.pantryPath,
    builder: (context, state) => const LunchPantryScreen(),
  ),
  GoRoute(
    path: LunchPlanningRoute.budgetPath,
    builder: (context, state) => const LunchBudgetScreen(),
  ),
  GoRoute(
    path: LunchPlanningRoute.pricesPath,
    builder: (context, state) => const LunchPricesScreen(),
  ),
  GoRoute(
    path: LunchPlanningRoute.picksPath,
    builder: (context, state) => const LunchKidPicksScreen(),
  ),
  GoRoute(
    path: LunchPlanningRoute.choosePath,
    builder: (context, state) {
      final childId =
          state.pathParameters[LunchPlanningRoute.childParameter] ?? '';
      final lunch = context.read<LunchBoardController>();
      final child = switch (lunch.board) {
        AsyncData(:final value) => value.childWeek(childId)?.child,
        _ => null,
      };
      return ChangeNotifierProvider(
        create: (context) =>
            LunchChooseController(
              lunchRepository: context.read<LunchRepository>(),
              choicesRepository: context.read<LunchChoicesRepository>(),
              householdId: HouseholdRoute.idFrom(state),
              childId: childId,
            )..follow(
              today: context.read<HouseholdClock>().today,
              week: lunch.week,
            ),
        child: LunchChooseScreen(
          childName: child?.member.displayName,
          onDone: () => context.pop(),
        ),
      );
    },
  ),
];

/// A kid device's chooser (lunch-box ADR-0008): its own plan and options,
/// for the week being planned in its household's zone — which it learns
/// from the household, as the kid home does.
GoRoute kidLunchChooseRoute(KidIdentity? Function() kidOf) => GoRoute(
  path: LunchPlanningRoute.kidChoosePath,
  builder: (context, state) {
    final kid = kidOf();
    // The moment between a sign-out and the redirect that follows it.
    if (kid == null) return const SessionGateScreen();
    return ChangeNotifierProvider(
      create: (context) => LunchChooseController(
        lunchRepository: context.read<LunchRepository>(),
        choicesRepository: context.read<LunchChoicesRepository>(),
        householdId: kid.householdId,
        childId: kid.memberId,
        todays: context
            .read<HouseholdRepository>()
            .watchHousehold(kid.householdId)
            .expand<CalendarDate>(
              (household) => household == null
                  ? const []
                  : [HouseholdClock(household.timeZone).today],
            ),
      ),
      child: const LunchChooseScreen(),
    );
  },
);
