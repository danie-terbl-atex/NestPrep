import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/accounts/state/session_controller.dart';
import '../features/calendar/data/calendar_repository.dart';
import '../features/calendar/state/calendar_controller.dart';
import '../features/calendar/ui/calendar_screen.dart';
import '../features/calendar_sync/data/calendar_sync_directory.dart';
import '../features/calendar_sync/data/calendar_sync_repository.dart';
import '../features/calendar_sync/state/connected_calendars_controller.dart';
import '../features/calendar_sync/ui/connected_calendars_screen.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/two_homes/ui/custody_calendar_scope.dart';
import '../shared/links/external_link_opener.dart';
import '../shared/time/household_clock.dart';
import 'app_router.dart';
import 'calendar_sync_route.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'viewer_member.dart';

/// The calendar's routes under the household shell — the week tab, and the
/// connected calendars pushed from it (calendar ADR-0001, ADR-0003) — in
/// their own file so the route table gains one line.
List<GoRoute> calendarRoutes(SessionController session) => [
  GoRoute(
    path: '${HouseholdRoute.path}/${HouseholdTab.week.segment}',
    // The only route whose controller follows another provider: the week
    // derives its birthdays from the household's profiles, so a rename or
    // a recolour has to reach it (birthdays ADR-0001).
    builder: (context, state) =>
        ChangeNotifierProxyProvider<HouseholdView, CalendarController>(
          create: (context) => calendarControllerFor(context, state),
          update: (context, view, controller) =>
              (controller ?? calendarControllerFor(context, state))
                ..showBirthdaysOf(view.members),
          // co-parenting: the linked children's days on the week, when two
          // homes is on (household ADR-0004).
          child: CustodyCalendarScope(
            householdId: HouseholdRoute.idFrom(state),
            child: CalendarScreen(
              onSelectTab: (tab) => goToTab(context, state, tab),
            ),
          ),
        ),
  ),
  // ---- calendar sync (calendar ADR-0003) ----
  GoRoute(
    path: CalendarSyncRoute.path,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => ConnectedCalendarsController(
        calendarSyncRepository: context.read<CalendarSyncRepository>(),
        calendarSyncDirectory: context.read<CalendarSyncDirectory>(),
        linkOpener: context.read<ExternalLinkOpener>(),
        householdId: HouseholdRoute.idFrom(state),
        viewerUid: session.uidOrEmpty,
        isAdmin: context.read<HouseholdView>().viewerIsAdmin,
        canConnect: context.read<HouseholdView>().permissions.canEdit(
          HouseholdArea.calendar,
        ),
      ),
      child: const ConnectedCalendarsScreen(),
    ),
  ),
];

CalendarController calendarControllerFor(
  BuildContext context,
  GoRouterState state,
) => CalendarController(
  calendarRepository: context.read<CalendarRepository>(),
  calendarSyncRepository: context.read<CalendarSyncRepository>(),
  householdClock: context.read<HouseholdClock>(),
  householdId: HouseholdRoute.idFrom(state),
  memberId: viewerMemberIdOf(context),
  householdMembers: context.read<HouseholdView>().members,
);
