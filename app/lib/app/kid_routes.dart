import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/accounts/data/auth_gateway.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/accounts/ui/session_gate_screen.dart';
import '../features/chore_points/data/points_repository.dart';
import '../features/chore_points/data/reward_repository.dart';
import '../features/chore_points/state/kid_points_controller.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/model/household_view.dart';
import '../features/kid_accounts/data/kid_device_repository.dart';
import '../features/kid_accounts/data/kid_sign_in_directory.dart';
import '../features/kid_accounts/state/kid_code_controller.dart';
import '../features/kid_accounts/state/kid_home_controller.dart';
import '../features/kid_accounts/state/kid_sign_in_controller.dart';
import '../features/kid_accounts/ui/kid_code_screen.dart';
import '../features/kid_accounts/ui/kid_home_screen.dart';
import '../features/kid_accounts/ui/kid_sign_in_screen.dart';
import '../features/lunch_box/data/lunch_choices_repository.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/state/lunch_choose_controller.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/todos/data/todo_repository.dart';
import '../shared/flags/feature_flag.dart';
import '../shared/flags/feature_flags_controller.dart';
import 'household_route.dart';
import 'lunch_planning_route.dart';
import 'lunch_planning_routes.dart';

/// Where kid sign-in lives in the route table (accounts ADR-0003), kept out of
/// `app_router.dart` so the router only has to spread it in.
///
/// Three places: the kid's way in, beside the other ways in; the kid's home,
/// the only screen a kid device ever shows; and the parent's screen, under the
/// household shell with the rest of managing people.
abstract final class KidRoute {
  static const codePath = KidCodeScreen.path;
  static const homePath = KidHomeScreen.path;

  static const manageSegment = 'kids';
  static const managePath = '${HouseholdRoute.path}/$manageSegment';

  static String managePathFor(String householdId) =>
      '/households/$householdId/$manageSegment';
}

/// The kid's way in and the kid's home — top-level routes, outside any
/// household shell, because a kid device has no household list to choose from.
List<RouteBase> kidRoutes(SessionController session) => [
  GoRoute(
    path: KidRoute.codePath,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => KidCodeController(
        kidSignInDirectory: context.read<KidSignInDirectory>(),
        authGateway: context.read<AuthGateway>(),
      ),
      child: const KidCodeScreen(),
    ),
  ),
  GoRoute(
    path: KidRoute.homePath,
    builder: (context, state) {
      final kid = session.kidIdentity;
      // The redirect only lets a kid session here, so this is the moment
      // between a sign-out and the redirect that follows it.
      if (kid == null) return const SessionGateScreen();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => KidHomeController(
              householdRepository: context.read<HouseholdRepository>(),
              todoRepository: context.read<TodoRepository>(),
              mealRepository: context.read<MealRepository>(),
              lunchRepository: context.read<LunchRepository>(),
              identity: kid,
            ),
          ),
          // The kid's stars follow the home: they open once it knows today
          // and the grant shows jobs (todos ADR-0003, accounts ADR-0004).
          ChangeNotifierProxyProvider<KidHomeController, KidPointsController>(
            create: (context) => KidPointsController(
              pointsRepository: context.read<PointsRepository>(),
              rewardRepository: context.read<RewardRepository>(),
              identity: kid,
            ),
            update: (context, home, stars) =>
                stars!..follow(home.areas, home.today),
          ),
          // Lunch to choose (lunch-box ADR-0008): opens once the home knows
          // today, only when the grant shows lunch and the switch is on.
          ChangeNotifierProxyProvider<KidHomeController, LunchChooseController>(
            create: (context) => LunchChooseController(
              lunchRepository: context.read<LunchRepository>(),
              choicesRepository: context.read<LunchChoicesRepository>(),
              householdId: kid.householdId,
              childId: kid.memberId,
            ),
            update: (context, home, choose) => choose!
              ..follow(
                today: home.today,
                show:
                    (home.areas?.lunch ?? false) &&
                    (context.read<FeatureFlagsController?>()?.isOn(
                          FeatureFlag.lunchKidPicks,
                        ) ??
                        false),
              ),
          ),
        ],
        child: const KidHomeScreen(),
      );
    },
  ),
  kidLunchChooseRoute(() => session.kidIdentity),
];

/// The parent's kid sign-in screen, under the household shell so it has the
/// household's profiles and clock.
GoRoute kidSignInRoute() => GoRoute(
  path: KidRoute.managePath,
  builder: (context, state) => ChangeNotifierProvider(
    create: (context) => KidSignInController(
      kidSignInDirectory: context.read<KidSignInDirectory>(),
      kidDeviceRepository: context.read<KidDeviceRepository>(),
      householdId: HouseholdRoute.idFrom(state),
      members: context.read<HouseholdView>().members,
    ),
    child: const KidSignInScreen(),
  ),
);

/// A kid device is only ever on its home — or choosing its lunch from there
/// (lunch-box ADR-0008). Every other location — the ways in, the household
/// screens, a stale deep link — sends it home.
String? redirectForKid(String location) =>
    location == KidRoute.homePath ||
        location == LunchPlanningRoute.kidChoosePath
    ? null
    : KidRoute.homePath;
