import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';
import '../features/nanny_hub/data/pickup_repository.dart';
import '../features/nanny_hub/state/photo_library.dart';
import '../features/nanny_hub/state/pickup_controller.dart';
import '../features/nanny_hub/ui/pickup_check_screen.dart';
import '../features/nanny_hub/ui/pickups_screen.dart';
import '../shared/time/household_clock.dart';
import 'nanny_hub_route.dart';

/// Who may collect and the school-run week (nanny-hub ADR-0005), for every
/// hub screen under the shell — so moving from the week to the door check
/// keeps one set of listeners. Created only when a pickup screen first asks.
Widget withPickups({required String householdId, required Widget child}) =>
    ChangeNotifierProvider(
      create: (context) {
        final view = context.read<HouseholdView>();
        return PickupController(
          pickupRepository: context.read<PickupRepository>(),
          photos: context.read<PhotoLibrary>(),
          householdId: householdId,
          memberId: view.viewerMember?.id ?? '',
          canEdit: view.permissions.isFamily,
          today: context.read<HouseholdClock>().today,
        );
      },
      child: child,
    );

/// The pickups screen and the door check for one child.
List<GoRoute> pickupRoutes() => [
  GoRoute(
    path: NannyHubRoute.pickupsPath,
    builder: (context, state) => const PickupsScreen(),
  ),
  GoRoute(
    path: NannyHubRoute.pickupCheckPath,
    builder: (context, state) => PickupCheckScreen(
      childId: NannyHubRoute.parameterFrom(state, NannyHubRoute.childParameter),
    ),
  ),
];
