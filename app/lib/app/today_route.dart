import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/family_profiles/data/child_profile_directory.dart';
import '../features/family_profiles/data/family_profile_repository.dart';
import '../features/family_profiles/state/family_controller.dart';
import '../features/groceries/data/grocery_repository.dart';
import '../features/groceries/state/grocery_list_controller.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/state/lunch_board_controller.dart';
import '../features/today/ui/today_screen.dart';
import '../features/todos/data/todo_repository.dart';
import '../features/todos/state/todo_controller.dart';
import '../shared/time/household_clock.dart';
import 'app_router.dart';
import 'calendar_routes.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'viewer_member.dart';

/// Today (design-system ADR-0009) reads through the same controllers its tabs
/// use, and opens only the ones the viewer's grant allows.
GoRoute todayRoute() => GoRoute(
  path: '${HouseholdRoute.path}/${HouseholdTab.today.segment}',
  builder: (context, state) {
    final view = context.read<HouseholdView>();
    final permissions = view.permissions;
    final householdId = HouseholdRoute.idFrom(state);
    final memberId = viewerMemberIdOf(context);
    final screen = TodayScreen(
      onSelectTab: (tab) => goToTab(context, state, tab),
    );
    final providers = <SingleChildWidget>[
      if (permissions.canUse(HouseholdArea.lunch)) ...[
        ChangeNotifierProxyProvider<HouseholdView, FamilyController>(
          create: (context) => FamilyController(
            familyProfileRepository: context.read<FamilyProfileRepository>(),
            childProfileDirectory: context.read<ChildProfileDirectory>(),
            householdId: householdId,
            household: view,
          ),
          update: (context, view, controller) =>
              controller!..followHousehold(view),
        ),
        ChangeNotifierProxyProvider<FamilyController, LunchBoardController>(
          create: (context) => LunchBoardController(
            lunchRepository: context.read<LunchRepository>(),
            householdClock: context.read<HouseholdClock>(),
            householdId: householdId,
            memberId: memberId,
            canEdit: permissions.canEdit(HouseholdArea.lunch),
          ),
          update: (context, family, controller) =>
              controller!..followRoster(family.roster),
        ),
      ],
      if (permissions.canUse(HouseholdArea.calendar))
        ChangeNotifierProvider(
          create: (context) => calendarControllerFor(context, state),
        ),
      if (permissions.canUse(HouseholdArea.todos))
        ChangeNotifierProvider(
          create: (context) => TodoController(
            todoRepository: context.read<TodoRepository>(),
            householdClock: context.read<HouseholdClock>(),
            householdId: householdId,
            memberId: memberId,
            isAdmin: view.viewerIsAdmin,
            isOwnOnly: permissions.hasOwnOnly(HouseholdArea.todos),
            canEdit: permissions.canEdit(HouseholdArea.todos),
          ),
        ),
      if (permissions.canUse(HouseholdArea.groceries))
        ChangeNotifierProvider(
          create: (context) => GroceryListController(
            groceryRepository: context.read<GroceryRepository>(),
            householdId: householdId,
            memberId: memberId,
          ),
        ),
    ];
    if (providers.isEmpty) return screen;
    return MultiProvider(providers: providers, child: screen);
  },
);
