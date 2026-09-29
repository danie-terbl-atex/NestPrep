import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/family_profiles/data/child_profile_directory.dart';
import '../features/family_profiles/data/family_profile_repository.dart';
import '../features/family_profiles/state/family_controller.dart';
import '../features/household/data/invite_sharer.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/data/platform_lunch_card_sharer.dart';
import '../features/lunch_box/state/lunch_board_controller.dart';
import '../features/lunch_box/state/lunch_share_controller.dart';
import '../features/lunch_box/ui/card/offscreen_lunch_card_renderer.dart';
import '../features/lunch_box/ui/lunch_library_screen.dart';
import '../features/lunch_box/ui/lunch_prep_screen.dart';
import '../features/lunch_box/ui/lunch_screen.dart';
import '../features/lunch_box/ui/planner/pdf_lunch_planner_composer.dart';
import '../features/lunch_box/ui/share/lunch_share_screen.dart';
import '../shared/time/household_clock.dart';
import 'app_router.dart';
import 'household_route.dart';
import 'lunch_planning_routes.dart';
import 'lunch_route.dart';
import 'viewer_member.dart';

/// Lunch boxes' routes under the household shell (lunch-box ADR-0001,
/// ADR-0004), in their own file so the route table gains one line.
///
/// The lunch board reads the children and their food rules through family
/// profiles' own controller rather than a second copy of its listeners
/// (`ENG-01`); both follow the household view, so a new child, a changed
/// role or a changed grant reaches them.
ShellRoute lunchRoutes() => ShellRoute(
  builder: (context, state, child) => MultiProvider(
    providers: [
      ChangeNotifierProxyProvider<HouseholdView, FamilyController>(
        create: (context) => FamilyController(
          familyProfileRepository: context.read<FamilyProfileRepository>(),
          childProfileDirectory: context.read<ChildProfileDirectory>(),
          householdId: HouseholdRoute.idFrom(state),
          household: context.read<HouseholdView>(),
        ),
        update: (context, view, controller) =>
            controller!..followHousehold(view),
      ),
      ChangeNotifierProxyProvider<FamilyController, LunchBoardController>(
        create: (context) => LunchBoardController(
          lunchRepository: context.read<LunchRepository>(),
          householdClock: context.read<HouseholdClock>(),
          householdId: HouseholdRoute.idFrom(state),
          memberId: viewerMemberIdOf(context),
          canEdit: context.read<HouseholdView>().permissions.canEdit(
            HouseholdArea.lunch,
          ),
        ),
        update: (context, family, controller) =>
            controller!..followRoster(family.roster),
      ),
      // lunch-box V2 — pantry, budget, kid picks (ADR-0006 to ADR-0008).
      ...lunchPlanningShellProviders(state),
    ],
    child: child,
  ),
  routes: [
    GoRoute(
      path: LunchRoute.path,
      builder: (context, state) =>
          LunchScreen(onSelectTab: (tab) => goToTab(context, state, tab)),
    ),
    GoRoute(
      path: LunchRoute.prepPath,
      builder: (context, state) => const LunchPrepScreen(),
    ),
    GoRoute(
      path: LunchRoute.libraryPath,
      builder: (context, state) => const LunchLibraryScreen(),
    ),
    // Made fresh on every visit, so a first name is chosen each time and
    // never remembered (lunch-box ADR-0005).
    GoRoute(
      path: LunchRoute.sharePath,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => LunchShareController(
          cardRenderer: const OffscreenLunchCardRenderer(),
          cardSharer: PlatformLunchCardSharer(),
          plannerComposer: PdfLunchPlannerComposer(),
          initialChildId: context.read<LunchBoardController>().selectedChildId,
          appLink: context.read<InviteSharer>().appLink,
        ),
        child: const LunchShareScreen(),
      ),
    ),
    ...lunchPlanningRoutes(),
  ],
);
