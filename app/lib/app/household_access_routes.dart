import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/accounts/state/session_controller.dart';
import '../features/calendar_sync/data/calendar_sync_directory.dart';
import '../features/calendar_sync/data/calendar_sync_repository.dart';
import '../features/calendar_sync/state/apple_calendar_sync.dart';
import '../features/calendar_sync/state/connected_calendars_controller.dart';
import '../features/family_profiles/data/child_profile_directory.dart';
import '../features/household/data/household_directory.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/data/invite_sharer.dart';
import '../features/household/model/access_grant.dart';
import '../features/household/model/access_level.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/household/state/close_household_controller.dart';
import '../features/household/state/invite_step_controller.dart';
import '../features/household/state/member_access_controller.dart';
import '../features/household/ui/close_household_screen.dart';
import '../features/household/ui/invite_step_screen.dart';
import '../features/household/ui/member_access_screen.dart';
import '../features/onboarding/state/setup_flow_controller.dart';
import '../features/onboarding/ui/setup_flow_screen.dart';
import '../shared/links/external_link_opener.dart';
import 'avatar_routes.dart';
import 'household_route.dart';

/// The routes the people screen opens under the household shell — the invite
/// step and the access editor (household ADR-0003), closing the household
/// (household ADR-0007) — kept in their own file so the route table gains
/// one line.
///
/// Each creates the controller its screen reads, like every other route
/// (foundation ADR-0006).
List<GoRoute> householdAccessRoutes() => [
  // While a new household's setup step is open this is the setup flow
  // (onboarding ADR-0001); afterwards, the people screen's invite.
  GoRoute(
    path: '${HouseholdRoute.path}/${HouseholdRoute.setupSegment}',
    builder: (context, state) {
      final view = context.read<HouseholdView>();
      final householdId = HouseholdRoute.idFrom(state);
      final invites = ChangeNotifierProvider(
        create: (context) => InviteStepController(
          householdRepository: context.read<HouseholdRepository>(),
          householdDirectory: context.read<HouseholdDirectory>(),
          inviteSharer: context.read<InviteSharer>(),
          childProfileDirectory: context.read<ChildProfileDirectory>(),
          householdId: householdId,
          householdName: view.household.name,
          coloursInUse: view.members.map((member) => member.color),
          viewerMemberId: view.viewerMember?.id,
        ),
      );
      if (!view.household.isWaitingOnInviteStep) {
        return MultiProvider(
          providers: [invites],
          child: const InviteStepScreen(),
        );
      }
      return MultiProvider(
        providers: [
          invites,
          ChangeNotifierProvider(create: (_) => SetupFlowController()),
          ChangeNotifierProvider(
            create: (context) => ConnectedCalendarsController(
              calendarSyncRepository: context.read<CalendarSyncRepository>(),
              calendarSyncDirectory: context.read<CalendarSyncDirectory>(),
              linkOpener: context.read<ExternalLinkOpener>(),
              householdId: householdId,
              viewerUid: context.read<SessionController>().uidOrEmpty,
              isAdmin: view.viewerIsAdmin,
              canConnect: view.permissions.canEdit(HouseholdArea.calendar),
              appleCalendar: context.read<AppleCalendarSync?>(),
            ),
          ),
        ],
        child: const SetupFlowScreen(),
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
  avatarStudioRoute(),
  // Closing the household for good (household ADR-0007).
  GoRoute(
    path: '${HouseholdRoute.path}/${HouseholdRoute.closeSegment}',
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => CloseHouseholdController(
        householdDirectory: context.read<HouseholdDirectory>(),
        householdId: HouseholdRoute.idFrom(state),
      ),
      child: const CloseHouseholdScreen(),
    ),
  ),
];
