import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/data/lunch_starter_box_repository.dart';
import '../features/lunch_box/state/fill_week_controller.dart';
import '../features/lunch_box/state/lunch_board_controller.dart';
import '../features/lunch_box/ui/fill_week_screen.dart';
import '../features/recipes/data/recipe_repository.dart';
import 'household_route.dart';
import 'lunch_route.dart';
import 'viewer_member.dart';

/// *Fill the week* under the lunch shell (lunch-box ADR-0020), for the child
/// the link names and the week the board is on. Made fresh on every visit,
/// following the board so every check is against the child, their rules and
/// the library the phone holds now.
GoRoute fillWeekRoute() => GoRoute(
  path: LunchRoute.fillWeekPath,
  builder: (context, state) =>
      ChangeNotifierProxyProvider<LunchBoardController, FillWeekController>(
        create: (context) => FillWeekController(
          starterBoxes: context.read<LunchStarterBoxRepository>(),
          recipes: context.read<RecipeRepository>(),
          lunchRepository: context.read<LunchRepository>(),
          householdId: HouseholdRoute.idFrom(state),
          memberId: viewerMemberIdOf(context),
          childId: state.uri.queryParameters[LunchRoute.childQuery] ?? '',
        ),
        update: (context, lunch, controller) =>
            controller!..followBoard(lunch.board),
        child: const FillWeekScreen(),
      ),
);
