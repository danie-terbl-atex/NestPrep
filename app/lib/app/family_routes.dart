import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/family_profiles/data/family_profile_repository.dart';
import '../features/family_profiles/model/family_access.dart';
import '../features/family_profiles/state/family_controller.dart';
import '../features/family_profiles/state/member_health_controller.dart';
import '../features/family_profiles/ui/family_member_screen.dart';
import '../features/family_profiles/ui/family_screen.dart';
import '../features/household/model/household_view.dart';
import 'family_route.dart';
import 'household_route.dart';

/// Family profiles' routes under the household shell (family-profiles
/// ADR-0001), in their own file so the route table gains one line.
///
/// The family and one person's profile share a shell, so they share one
/// controller and one pair of listeners. It follows the household view
/// because a rename, a new member or a change of role — or of what the viewer
/// may see (household ADR-0003) — has to reach it.
ShellRoute familyRoutes() => ShellRoute(
  builder: (context, state, child) =>
      ChangeNotifierProxyProvider<HouseholdView, FamilyController>(
        create: (context) => FamilyController(
          familyProfileRepository: context.read<FamilyProfileRepository>(),
          householdId: HouseholdRoute.idFrom(state),
          household: context.read<HouseholdView>(),
        ),
        update: (context, view, controller) =>
            controller!..followHousehold(view),
        child: child,
      ),
  routes: [
    GoRoute(
      path: FamilyRoute.path,
      builder: (context, state) => const FamilyScreen(),
    ),
    GoRoute(
      path: FamilyRoute.memberPath,
      builder: (context, state) {
        final memberId = FamilyRoute.memberIdFrom(state);
        return ChangeNotifierProvider(
          create: (context) => MemberHealthController(
            familyProfileRepository: context.read<FamilyProfileRepository>(),
            householdId: HouseholdRoute.idFrom(state),
            memberId: memberId,
            isVisible: FamilyAccess.of(context.read<HouseholdView>())
                .canSeeHealth(memberId),
          ),
          child: FamilyMemberScreen(memberId: memberId),
        );
      },
    ),
  ],
);
