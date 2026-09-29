import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/chore_points/data/points_directory.dart';
import '../features/chore_points/data/points_repository.dart';
import '../features/chore_points/data/reward_repository.dart';
import '../features/chore_points/state/chore_points_controller.dart';
import '../features/chore_points/ui/chore_points_screen.dart';
import '../features/household/model/household_view.dart';
import 'household_route.dart';
import 'viewer_member.dart';

/// Where a parent runs stars and rewards (todos ADR-0003): one screen under
/// the household shell, pushed from the to-dos tab, with the household in the
/// path so it deep-links and back does the obvious thing (`FE-17`).
abstract final class ChorePointsRoute {
  static const segment = 'stars';
  static const path = '${HouseholdRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';
}

/// The route, in its own file so the route table gains one line. It follows
/// the household view, so a child added or a role changed reaches the board.
GoRoute chorePointsRoute() => GoRoute(
  path: ChorePointsRoute.path,
  builder: (context, state) =>
      ChangeNotifierProxyProvider<HouseholdView, ChorePointsController>(
        create: (context) => ChorePointsController(
          pointsRepository: context.read<PointsRepository>(),
          rewardRepository: context.read<RewardRepository>(),
          pointsDirectory: context.read<PointsDirectory>(),
          householdId: HouseholdRoute.idFrom(state),
          memberId: viewerMemberIdOf(context),
          members: context.read<HouseholdView>().members,
        ),
        update: (context, view, controller) =>
            controller!..followMembers(view.members),
        child: const ChorePointsScreen(),
      ),
);
