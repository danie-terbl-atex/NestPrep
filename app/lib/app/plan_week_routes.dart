import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/groceries/data/grocery_repository.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/state/lunch_board_controller.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/plan_week/data/plan_week_groceries.dart';
import '../features/plan_week/data/week_planner.dart';
import '../features/plan_week/state/plan_week_controller.dart';
import '../features/plan_week/state/plan_week_saver.dart';
import '../features/plan_week/ui/plan_week_screen.dart';
import 'household_route.dart';
import 'plan_week_route.dart';
import 'viewer_member.dart';

/// *Plan my week* under the lunch shell (lunch-box ADR-0011). Made fresh on
/// every visit, for the week the board is on, following the board so the
/// plan is checked against the children and rules the phone holds now.
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
        planner: context.read<WeekPlanner>(),
        saver: PlanWeekSaver(
          lunchRepository: context.read<LunchRepository>(),
          mealRepository: context.read<MealRepository>(),
          householdId: householdId,
          memberId: memberId,
        ),
        groceries: PlanWeekGroceries(
          groceryRepository: context.read<GroceryRepository>(),
          householdId: householdId,
          memberId: memberId,
        ),
        mealRepository: context.read<MealRepository>(),
        householdId: householdId,
        week: context.read<LunchBoardController>().week,
        mayPlanDinners: context.read<HouseholdView>().permissions.canEdit(
          HouseholdArea.meals,
        ),
      ),
      update: (context, lunch, controller) =>
          controller!..followBoard(lunch.board),
      child: const PlanWeekScreen(),
    );
  },
);
