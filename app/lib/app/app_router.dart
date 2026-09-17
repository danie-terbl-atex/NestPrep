import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/gallery/design_gallery_screen.dart';
import '../features/accounts/model/session.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/accounts/ui/session_gate_screen.dart';
import '../features/accounts/ui/sign_in_screen.dart';
import '../features/calendar/data/calendar_repository.dart';
import '../features/calendar/state/calendar_controller.dart';
import '../features/calendar/ui/calendar_screen.dart';
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
import '../features/meal_planning/data/meal_repository.dart';
import '../features/meal_planning/state/meal_plan_controller.dart';
import '../features/meal_planning/ui/meal_plan_screen.dart';
import '../features/todos/data/todo_repository.dart';
import '../features/todos/state/todo_controller.dart';
import '../features/todos/ui/todo_screen.dart';
import '../shared/async/async_state.dart';
import '../shared/time/household_clock.dart';
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
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdTab.week.segment}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => CalendarController(
              calendarRepository: context.read<CalendarRepository>(),
              householdClock: context.read<HouseholdClock>(),
              householdId: HouseholdRoute.idFrom(state),
              memberId: _viewerMemberId(context),
            ),
            child: CalendarScreen(
              onSelectTab: (tab) => _goToTab(context, state, tab),
            ),
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
    if (kDebugMode)
      GoRoute(
        path: DesignGalleryScreen.path,
        builder: (context, state) => const DesignGalleryScreen(),
      ),
  ],
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
/// Signed out, only the sign-in screen exists; signed in with no household, only
/// the gate; signed in with one, everything under it. The design gallery is
/// exempt because it renders no data and debug builds use it before sign-in.
@visibleForTesting
String? redirectForSession(SessionController session, String location) {
  if (kDebugMode && location == DesignGalleryScreen.path) return null;

  final state = session.session;
  if (state is! AsyncData<Session>) {
    return location == SessionGateScreen.path ? null : SessionGateScreen.path;
  }
  if (state.value is SignedOut) {
    return location == SignInScreen.path ? null : SignInScreen.path;
  }

  final householdId = session.activeHouseholdId;
  if (householdId == null) {
    return location == HouseholdGateScreen.path
        ? null
        : HouseholdGateScreen.path;
  }

  const waitingRooms = [
    SessionGateScreen.path,
    SignInScreen.path,
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
