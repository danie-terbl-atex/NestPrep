import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/kid_routines/data/kid_routine_repository.dart';
import '../features/kid_routines/state/kid_routines_controller.dart';
import '../features/kid_routines/ui/kid_routines_screen.dart';
import 'household_route.dart';
import 'viewer_member.dart';

/// Where a parent sets up the children's routines (kid-routines ADR-0001):
/// one screen under the household shell, pushed from the Chores view, with
/// the household in the path so back does the obvious thing (`FE-17`).
abstract final class KidRoutinesRoute {
  static const segment = 'kid-routines';
  static const path = '${HouseholdRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';
}

GoRoute kidRoutinesRoute() => GoRoute(
  path: KidRoutinesRoute.path,
  builder: (context, state) =>
      ChangeNotifierProxyProvider<HouseholdView, KidRoutinesController>(
        create: (context) {
          final view = context.read<HouseholdView>();
          return KidRoutinesController(
            repository: context.read<KidRoutineRepository>(),
            householdId: HouseholdRoute.idFrom(state),
            memberId: viewerMemberIdOf(context),
            canEdit: view.permissions.canEdit(HouseholdArea.todos),
            setsStars: view.permissions.isFamily,
            members: view.members,
          );
        },
        update: (context, view, controller) =>
            controller!..followMembers(view.members),
        child: const KidRoutinesScreen(),
      ),
);
