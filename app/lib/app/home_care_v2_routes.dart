import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/home_care/data/routine_repository.dart';
import '../features/home_care/state/home_care_controller.dart';
import '../features/home_care/state/routines_controller.dart';
import '../features/home_care/ui/languages_screen.dart';
import '../features/home_care/ui/routines_screen.dart';
import '../features/home_care/ui/stock_screen.dart';
import '../features/home_care/ui/today_rooms_screen.dart';
import '../shared/time/household_clock.dart';
import 'home_care_route.dart';
import 'household_route.dart';

/// Home care's V2 routes (home-care ADR-0004 to ADR-0006), inside the
/// home-care shell: the stock tracker and everybody's language read the
/// shell's controllers; the routines overview and today's rooms share one
/// more, so walking between them opens no second listener.
List<RouteBase> homeCareV2Routes() => [
  GoRoute(
    path: HomeCareRoute.stockPath,
    builder: (context, state) => const StockScreen(),
  ),
  GoRoute(
    path: HomeCareRoute.languagesPath,
    builder: (context, state) => const LanguagesScreen(),
  ),
  ShellRoute(
    builder: (context, state, child) =>
        ChangeNotifierProxyProvider<HomeCareController, RoutinesController>(
          create: (context) => RoutinesController(
            routineRepository: context.read<RoutineRepository>(),
            householdId: HouseholdRoute.idFrom(state),
            today: context.read<HouseholdClock>().today,
            access: context.read<HomeCareController>().access,
          ),
          update: (context, home, controller) =>
              controller!..follow(home.access, home.board),
          child: child,
        ),
    routes: [
      GoRoute(
        path: HomeCareRoute.routinesPath,
        builder: (context, state) => const RoutinesScreen(),
      ),
      GoRoute(
        path: HomeCareRoute.todayPath,
        builder: (context, state) => const TodayRoomsScreen(),
      ),
    ],
  ),
];
