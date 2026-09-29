import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/gallery/design_gallery_screen.dart';
import '../features/accounts/data/auth_gateway.dart';
import '../features/accounts/model/session.dart';
import '../features/accounts/state/password_reset_controller.dart';
import '../features/accounts/state/register_controller.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/accounts/ui/forgot_password_screen.dart';
import '../features/accounts/ui/register_screen.dart';
import '../features/accounts/ui/session_gate_screen.dart';
import '../features/accounts/ui/sign_in_screen.dart';
import '../features/accounts/ui/verify_email_screen.dart';
import '../features/calendar/data/calendar_repository.dart';
import '../features/calendar/state/calendar_controller.dart';
import '../features/calendar/ui/calendar_screen.dart';
import '../features/calendar_sync/data/calendar_sync_directory.dart';
import '../features/calendar_sync/data/calendar_sync_repository.dart';
import '../features/calendar_sync/state/connected_calendars_controller.dart';
import '../features/calendar_sync/ui/connected_calendars_screen.dart';
import '../features/documents/data/document_directory.dart';
import '../features/documents/data/document_opener.dart';
import '../features/documents/data/document_picker.dart';
import '../features/documents/data/document_repository.dart';
import '../features/documents/data/document_store.dart';
import '../features/documents/state/document_library_controller.dart';
import '../features/documents/ui/document_folder_screen.dart';
import '../features/documents/ui/document_library_screen.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/groceries/state/grocery_list_controller.dart';
import '../features/groceries/ui/grocery_list_screen.dart';
import '../features/household/data/household_directory.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/model/household.dart';
import '../features/household/model/household_view.dart';
import '../features/household/state/household_controller.dart';
import '../features/household/state/household_gate_controller.dart';
import '../features/household/ui/household_gate_screen.dart';
import '../features/household/ui/household_screen.dart';
import '../features/live_location/data/live_location_repository.dart';
import '../features/live_location/data/location_reporter.dart';
import '../features/live_location/state/live_location_controller.dart';
import '../features/live_location/ui/live_location_screen.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/meal_planning/state/meal_plan_controller.dart';
import '../features/meal_planning/ui/meal_plan_screen.dart';
import '../features/todos/data/todo_repository.dart';
import '../features/todos/state/todo_controller.dart';
import '../features/todos/ui/todo_screen.dart';
import '../shared/async/async_state.dart';
import '../shared/links/external_link_opener.dart';
import '../shared/time/household_clock.dart';
import 'calendar_sync_route.dart';
import 'design_gallery_access.dart';
import 'documents_route.dart';
import 'household_route.dart';
import 'household_shell.dart';

/// A route creates the controller its screen reads, so the controller's
/// lifetime is the screen's (foundation ADR-0006). The household shell is the
/// one exception a level up: the household and its members are read once for
/// every tab under it.
GoRouter createAppRouter(SessionController session) => GoRouter(
  refreshListenable: session,
  initialLocation: SessionGateScreen.path,
  redirect: (context, state) =>
      redirectForSession(session, state.matchedLocation),
  routes: [
    GoRoute(
      path: SessionGateScreen.path,
      builder: (context, state) => const SessionGateScreen(),
    ),
    GoRoute(
      path: SignInScreen.path,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: RegisterScreen.path,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) =>
            RegisterController(authGateway: context.read<AuthGateway>()),
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: ForgotPasswordScreen.path,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) =>
            PasswordResetController(authGateway: context.read<AuthGateway>()),
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: VerifyEmailScreen.path,
      builder: (context, state) => const VerifyEmailScreen(),
    ),
    GoRoute(
      path: HouseholdGateScreen.path,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => HouseholdGateController(
          householdDirectory: context.read<HouseholdDirectory>(),
          suggestedName: session.suggestedDisplayName,
          defaultTimeZone: Household.defaultTimeZone,
        ),
        child: const HouseholdGateScreen(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => ChangeNotifierProvider(
        create: (context) => HouseholdController(
          householdRepository: context.read<HouseholdRepository>(),
          householdDirectory: context.read<HouseholdDirectory>(),
          householdId: HouseholdRoute.idFrom(state),
          viewerUid: session.uidOrEmpty,
        ),
        child: HouseholdShell(child: child),
      ),
      routes: [
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdRoute.householdSegment}',
          builder: (context, state) => const HouseholdScreen(),
        ),
        // A shell of its own, so the folders screen and a folder share one
        // controller and one pair of listeners rather than opening a second
        // set on the way in (documents ADR-0001).
        ShellRoute(
          builder: (context, state, child) => ChangeNotifierProvider(
            create: (context) => DocumentLibraryController(
              documentRepository: context.read<DocumentRepository>(),
              documentStore: context.read<DocumentStore>(),
              documentDirectory: context.read<DocumentDirectory>(),
              documentPicker: context.read<DocumentPicker>(),
              documentOpener: context.read<DocumentOpener>(),
              householdId: HouseholdRoute.idFrom(state),
              memberId: _viewerMemberId(context),
              viewerUid: session.uidOrEmpty,
              isAdmin: context.read<HouseholdView>().viewerIsAdmin,
            ),
            child: child,
          ),
          routes: [
            GoRoute(
              path: DocumentsRoute.path,
              builder: (context, state) => const DocumentLibraryScreen(),
            ),
            GoRoute(
              path: DocumentsRoute.folderPath,
              builder: (context, state) => DocumentFolderScreen(
                folderId: DocumentsRoute.folderIdFrom(state),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdRoute.whereSegment}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => LiveLocationController(
              liveLocationRepository: context.read<LiveLocationRepository>(),
              locationReporter: context.read<LocationReporter>(),
              householdId: HouseholdRoute.idFrom(state),
              viewerMemberId: _viewerMemberId(context),
              members: context.read<HouseholdView>().members,
            ),
            child: const LiveLocationScreen(),
          ),
        ),
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdTab.week.segment}',
          // The only route whose controller follows another provider: the week
          // derives its birthdays from the household's profiles, so a rename or
          // a recolour has to reach it (birthdays ADR-0001).
          builder: (context, state) =>
              ChangeNotifierProxyProvider<HouseholdView, CalendarController>(
                create: (context) => _calendarController(context, state),
                update: (context, view, controller) =>
                    (controller ?? _calendarController(context, state))
                      ..showBirthdaysOf(view.members),
                child: CalendarScreen(
                  onSelectTab: (tab) => _goToTab(context, state, tab),
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
            ),
            child: const ConnectedCalendarsScreen(),
          ),
        ),
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdTab.todos.segment}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => TodoController(
              todoRepository: context.read<TodoRepository>(),
              householdClock: context.read<HouseholdClock>(),
              householdId: HouseholdRoute.idFrom(state),
              memberId: _viewerMemberId(context),
              isAdmin: context.read<HouseholdView>().viewerIsAdmin,
            ),
            child: TodoScreen(
              onSelectTab: (tab) => _goToTab(context, state, tab),
            ),
          ),
        ),
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdTab.meals.segment}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => MealPlanController(
              mealRepository: context.read<MealRepository>(),
              householdClock: context.read<HouseholdClock>(),
              householdId: HouseholdRoute.idFrom(state),
              memberId: _viewerMemberId(context),
            ),
            child: MealPlanScreen(
              onSelectTab: (tab) => _goToTab(context, state, tab),
            ),
          ),
        ),
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdTab.groceries.segment}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => GroceryListController(
              groceryRepository: context.read<GroceryRepository>(),
              householdId: HouseholdRoute.idFrom(state),
              memberId: _viewerMemberId(context),
            ),
            child: GroceryListScreen(
              onSelectTab: (tab) => _goToTab(context, state, tab),
            ),
          ),
        ),
      ],
    ),
    if (DesignGalleryAccess.isAvailable)
      GoRoute(
        path: DesignGalleryScreen.path,
        builder: (context, state) => const DesignGalleryScreen(),
      ),
  ],
);

CalendarController _calendarController(
  BuildContext context,
  GoRouterState state,
) => CalendarController(
  calendarRepository: context.read<CalendarRepository>(),
  calendarSyncRepository: context.read<CalendarSyncRepository>(),
  householdClock: context.read<HouseholdClock>(),
  householdId: HouseholdRoute.idFrom(state),
  memberId: _viewerMemberId(context),
  householdMembers: context.read<HouseholdView>().members,
);

void _goToTab(BuildContext context, GoRouterState state, HouseholdTab tab) {
  context.go(HouseholdRoute.pathFor(HouseholdRoute.idFrom(state), tab));
}

/// The profile the signed-in account claimed here. Everything a member creates
/// is stamped with it, and the rules check it against `claimedBy` (household
/// ADR-0001).
String _viewerMemberId(BuildContext context) =>
    context.read<HouseholdView>().viewerMember?.id ?? '';

/// Where a caller in this session belongs, or null to leave them where they are.
///
/// Signed out, only the three ways in exist; signed in with an address nobody
/// has proved and no household, only the confirm screen; signed in with no
/// household, only the gate; signed in with one, everything under it. The design
/// gallery is exempt because it renders no data and debug builds use it before
/// sign-in.
@visibleForTesting
String? redirectForSession(SessionController session, String location) {
  if (DesignGalleryAccess.isAvailable && location == DesignGalleryScreen.path) {
    return null;
  }

  final state = session.session;
  if (state is! AsyncData<Session>) {
    return location == SessionGateScreen.path ? null : SessionGateScreen.path;
  }
  if (state.value is SignedOut) {
    const waysIn = [
      SignInScreen.path,
      RegisterScreen.path,
      ForgotPasswordScreen.path,
    ];
    return waysIn.contains(location) ? null : SignInScreen.path;
  }

  final householdId = session.activeHouseholdId;

  // An unproved address cannot create or join a household — the callables
  // refuse it (accounts ADR-0002) — so the gate would be a dead end. Somebody
  // who is already in a household is left alone: they got in before the rule
  // existed, or through Google, and locking them out of the app they are using
  // would punish them for our change.
  if (!session.emailVerified && householdId == null) {
    return location == VerifyEmailScreen.path ? null : VerifyEmailScreen.path;
  }
  if (householdId == null) {
    return location == HouseholdGateScreen.path
        ? null
        : HouseholdGateScreen.path;
  }

  const waitingRooms = [
    SessionGateScreen.path,
    SignInScreen.path,
    RegisterScreen.path,
    ForgotPasswordScreen.path,
    VerifyEmailScreen.path,
    HouseholdGateScreen.path,
  ];
  if (waitingRooms.contains(location)) {
    return HouseholdRoute.homeFor(householdId);
  }

  // A household route for a household this account no longer belongs to — it
  // was left on another device, or the link is somebody else's.
  if (location.startsWith('/households/') &&
      !location.startsWith('/households/$householdId/')) {
    return HouseholdRoute.homeFor(householdId);
  }
  return null;
}
