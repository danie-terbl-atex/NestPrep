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
import '../features/groceries/data/grocery_repository.dart';
import '../features/groceries/state/grocery_list_controller.dart';
import '../features/groceries/ui/grocery_list_screen.dart';
import '../features/household/data/household_directory.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/model/household.dart';
import '../features/household/model/household_area.dart';
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
import '../features/product_analytics/data/beta_numbers_repository.dart';
import '../features/product_analytics/state/beta_numbers_controller.dart';
import '../features/product_analytics/ui/beta_numbers_screen.dart';
import '../features/todos/data/todo_repository.dart';
import '../features/todos/state/todo_controller.dart';
import '../features/todos/ui/todo_screen.dart';
import '../shared/async/async_state.dart';
import '../shared/time/household_clock.dart';
import 'calendar_routes.dart';
import 'chore_points_route.dart';
import 'design_gallery_access.dart';
import 'documents_shell.dart';
import 'family_routes.dart';
import 'household_access_routes.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'kid_routes.dart';
import 'viewer_member.dart';

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
    // Kid sign-in: the kid's way in and the kid's home (accounts ADR-0003).
    ...kidRoutes(session),
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
        child: HouseholdShell(location: state.uri.path, child: child),
      ),
      routes: [
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdRoute.householdSegment}',
          builder: (context, state) => const HouseholdScreen(),
        ),
        // household phase 2: the invite step and the access editor (household
        // ADR-0003).
        ...householdAccessRoutes(),
        // Documents — folders, vaults, their log and search — in a shell of
        // its own (documents ADR-0001, ADR-0003).
        documentsShellRoute(session),
        // The parent's kid sign-in screen (accounts ADR-0003).
        kidSignInRoute(),
        // family-profiles (family-profiles ADR-0001): the family and one
        // person's profile.
        familyRoutes(),
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdRoute.whereSegment}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => LiveLocationController(
              liveLocationRepository: context.read<LiveLocationRepository>(),
              locationReporter: context.read<LocationReporter>(),
              householdId: HouseholdRoute.idFrom(state),
              viewerMemberId: viewerMemberIdOf(context),
              members: context.read<HouseholdView>().members,
            ),
            child: const LiveLocationScreen(),
          ),
        ),
        // todos phase 2: a parent's stars and rewards (todos ADR-0003).
        chorePointsRoute(),
        // The week, and calendar sync's connected calendars (calendar
        // ADR-0001, ADR-0003).
        ...calendarRoutes(session),
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdTab.todos.segment}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => TodoController(
              todoRepository: context.read<TodoRepository>(),
              householdClock: context.read<HouseholdClock>(),
              householdId: HouseholdRoute.idFrom(state),
              memberId: viewerMemberIdOf(context),
              isAdmin: context.read<HouseholdView>().viewerIsAdmin,
              // household phase 2 (household ADR-0003).
              isOwnOnly: context.read<HouseholdView>().permissions.hasOwnOnly(
                HouseholdArea.todos,
              ),
              canEdit: context.read<HouseholdView>().permissions.canEdit(
                HouseholdArea.todos,
              ),
            ),
            child: TodoScreen(
              onSelectTab: (tab) => goToTab(context, state, tab),
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
              memberId: viewerMemberIdOf(context),
            ),
            child: MealPlanScreen(
              onSelectTab: (tab) => goToTab(context, state, tab),
            ),
          ),
        ),
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdTab.groceries.segment}',
          builder: (context, state) => ChangeNotifierProvider(
            create: (context) => GroceryListController(
              groceryRepository: context.read<GroceryRepository>(),
              householdId: HouseholdRoute.idFrom(state),
              memberId: viewerMemberIdOf(context),
            ),
            child: GroceryListScreen(
              onSelectTab: (tab) => goToTab(context, state, tab),
            ),
          ),
        ),
      ],
    ),
    // ---- product analytics (product-analytics ADR-0001) ----
    // Outside the household shell: the numbers are about every family, never
    // a view of this one. Offered from the account sheet to a reader only; the
    // rules refuse the numbers to anybody else who finds the path.
    GoRoute(
      path: BetaNumbersScreen.path,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => BetaNumbersController(
          betaNumbersRepository: context.read<BetaNumbersRepository>(),
        ),
        child: const BetaNumbersScreen(),
      ),
    ),
    if (DesignGalleryAccess.isAvailable)
      GoRoute(
        path: DesignGalleryScreen.path,
        builder: (context, state) => const DesignGalleryScreen(),
      ),
  ],
);

/// Moves between the four tabs of one household.
void goToTab(BuildContext context, GoRouterState state, HouseholdTab tab) {
  context.go(HouseholdRoute.pathFor(HouseholdRoute.idFrom(state), tab));
}

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
      KidRoute.codePath,
    ];
    return waysIn.contains(location) ? null : SignInScreen.path;
  }
  // A kid device has one screen (accounts ADR-0003).
  if (state.value is KidSignedIn) return redirectForKid(location);

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
