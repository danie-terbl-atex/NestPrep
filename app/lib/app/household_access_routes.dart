import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/data/household_directory.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/data/invite_sharer.dart';
import '../features/household/model/access_grant.dart';
import '../features/household/model/access_level.dart';
import '../features/household/model/household_view.dart';
import '../features/household/state/invite_step_controller.dart';
import '../features/household/state/member_access_controller.dart';
import '../features/household/ui/invite_step_screen.dart';
import '../features/household/ui/member_access_screen.dart';
import 'household_route.dart';

/// The two routes household phase 2 adds under the household shell (household
/// ADR-0003), kept in their own file so the route table gains one line.
///
/// Each creates the controller its screen reads, like every other route
/// (foundation ADR-0006).
List<GoRoute> householdAccessRoutes() => [
  GoRoute(
    path: '${HouseholdRoute.path}/${HouseholdRoute.setupSegment}',
    builder: (context, state) {
      final view = context.read<HouseholdView>();
      return ChangeNotifierProvider(
        create: (context) => InviteStepController(
          householdRepository: context.read<HouseholdRepository>(),
          householdDirectory: context.read<HouseholdDirectory>(),
          inviteSharer: context.read<InviteSharer>(),
          householdId: HouseholdRoute.idFrom(state),
          householdName: view.household.name,
          coloursInUse: view.members.map((member) => member.color),
        ),
        child: const InviteStepScreen(),
      );
    },
  ),
  GoRoute(
    path: '${HouseholdRoute.path}/${HouseholdRoute.accessSegment}',
    builder: (context, state) {
      final memberId = HouseholdRoute.memberIdFrom(state);
      final view = context.read<HouseholdView>();
      final member = view.memberById(memberId);
      return ChangeNotifierProvider(
        create: (context) => MemberAccessController(
          householdDirectory: context.read<HouseholdDirectory>(),
          householdId: HouseholdRoute.idFrom(state),
          memberId: memberId,
          startingFrom: member == null
              ? AccessGrant.uniform(AccessLevel.none)
              : view.permissionsOf(member).grant ??
                    AccessGrant.uniform(AccessLevel.none),
        ),
        child: MemberAccessScreen(memberId: memberId),
      );
    },
  ),
];
