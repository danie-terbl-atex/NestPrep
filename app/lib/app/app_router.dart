import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/gallery/design_gallery_screen.dart';
import '../design/nest_kit.dart';
import '../features/accounts/data/auth_gateway.dart';
import '../features/accounts/state/password_reset_controller.dart';
import '../features/accounts/state/register_controller.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/accounts/ui/forgot_password_screen.dart';
import '../features/accounts/ui/register_screen.dart';
import '../features/accounts/ui/session_gate_screen.dart';
import '../features/accounts/ui/sign_in_screen.dart';
import '../features/household/data/household_directory.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/model/household.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/household/state/household_controller.dart';
import '../features/household/state/household_gate_controller.dart';
import '../features/household/state/join_invite_controller.dart';
import '../features/household/state/pending_invite.dart';
import '../features/household/ui/household_gate_screen.dart';
import '../features/household/ui/household_more_screen.dart';
import '../features/household/ui/household_screen.dart';
import '../features/household/ui/join_invite_screen.dart';
import '../features/product_analytics/data/beta_numbers_repository.dart';
import '../features/product_analytics/state/beta_numbers_controller.dart';
import '../features/product_analytics/ui/beta_numbers_screen.dart';
import '../features/todos/data/todo_repository.dart';
import '../features/todos/state/todo_controller.dart';
import '../features/todos/ui/todo_screen.dart';
import '../shared/time/household_clock.dart';
import 'account_routes.dart';
import 'assistants_routes.dart';
import 'basket_compare_routes.dart';
import 'calendar_routes.dart';
import 'checkers_link_routes.dart';
import 'chore_points_route.dart';
import 'design_gallery_access.dart';
import 'documents_shell.dart';
import 'family_routes.dart';
import 'grocery_route.dart';
import 'home_care_routes.dart';
import 'household_access_routes.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'household_tab_navigation.dart';
import 'kid_routes.dart';
import 'live_location_routes.dart';
import 'lunch_routes.dart';
import 'meals_routes.dart';
import 'nanny_hub_routes.dart';
import 'notifications_routes.dart';
import 'photo_frame_routes.dart';
import 'pnp_link_routes.dart';
import 'referral_routes.dart';
import 'session_redirect.dart';
import 'subscription_routes.dart';
import 'today_route.dart';
import 'two_homes_routes.dart';
import 'viewer_member.dart';

/// A route creates the controller its screen reads, so the controller's
/// lifetime is the screen's (foundation ADR-0006). The household shell is the
/// one exception a level up: the household and its members are read once for
/// every tab under it.
GoRouter createAppRouter(
  SessionController session,
  PendingInvite pendingInvite,
) => GoRouter(
  refreshListenable: Listenable.merge([session, pendingInvite]),
  initialLocation: SessionGateScreen.path,
  redirect: (context, state) => redirectForSession(
    session,
    state.matchedLocation,
    pendingInviteCode: pendingInvite.code,
  ),
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
    // Kid sign-in: the kid's way in and the kid's home (accounts ADR-0003).
    ...kidRoutes(session),
    // The account centre, download, delete and the legal pages (accounts
    // ADR-0005, ADR-0006).
    ...accountRoutes(),
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
    GoRoute(
      path: JoinInviteScreen.path,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => JoinInviteController(
          householdDirectory: context.read<HouseholdDirectory>(),
          pendingInvite: pendingInvite,
        )..load(),
        child: const JoinInviteScreen(),
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
        // nanny hub (nanny-hub ADR-0001 to ADR-0003): the hub, a child's card,
        // the emergency sheet, the guide, rules, checklists, shift mode and
        // a shift's summary.
        nannyHubRoutes(),
        // home-care (home-care ADR-0001): jobs, rooms, products.
        homeCareRoutes(session),
        // lunch-box (lunch-box ADR-0001, ADR-0004): the lunch tab, its prep
        // list and its library.
        lunchRoutes(),
        // subscriptions: plan and billing (subscriptions ADR-0001).
        subscriptionRoute(),
        // co-parenting: a child in two homes (household ADR-0004).
        ...twoHomesRoutes(),
        // referrals: give a month, get a month (subscriptions ADR-0002).
        referralRoute(),
        // photo frames on the wall (photo-frames ADR-0001).
        photoFrameRoute(),
        // assistants: nestprep in Claude and ChatGPT (assistants ADR-0001).
        assistantsRoute(session),
        // Linking a Checkers account, for Add to Checkers (the Checkers build
        // contract).
        checkersLinkRoute(),
        // Compare shops, over the grocery list (basket-compare ADR-0001).
        basketCompareRoute(),
        // Linking a Pick n Pay account, for its cart (add-to-pnp ADR-0003).
        pnpLinkRoute(),
        // notifications: the inbox, its settings and one notification opened
        // (notifications ADR-0001 to ADR-0003).
        ...notificationsRoutes(),
        // family location: the map, a member's day and the household's
        // places (live-location ADR-0003 to ADR-0007).
        ...liveLocationRoutes(),
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
              kidIds: context.read<HouseholdView>().kidMemberIds,
            ),
            child: TodoScreen(
              onSelectTab: (tab) => goToTab(context, state, tab),
            ),
          ),
        ),
        // Meals, under Food: recipes, a recipe's page and this week
        // (design-system ADR-0015, ADR-0017, recipes ADR-0003).
        mealsRoutes(),
        // groceries phase 2: the list and the week's plans against it
        // (groceries ADR-0002).
        groceryRoute(),
        todayRoute(),
        for (final group in const [HouseholdTab.lists, HouseholdTab.food])
          GoRoute(
            path: '${HouseholdRoute.path}/${group.segment}',
            builder: (context, state) => const NestLoadingView(),
          ),
        // More: the people and every place beyond the bar (design-system
        // ADR-0005).
        GoRoute(
          path: '${HouseholdRoute.path}/${HouseholdTab.more.segment}',
          builder: (context, state) => HouseholdMoreScreen(
            onSelectTab: (tab) => goToTab(context, state, tab),
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
