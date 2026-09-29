import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';
import '../features/nanny_hub/data/booking_repository.dart';
import '../features/nanny_hub/data/house_code_repository.dart';
import '../features/nanny_hub/data/shift_directory.dart';
import '../features/nanny_hub/state/bookings_controller.dart';
import '../features/nanny_hub/state/house_codes_controller.dart';
import '../features/nanny_hub/state/shift_pass_controller.dart';
import '../features/nanny_hub/ui/bookings_screen.dart';
import '../features/nanny_hub/ui/house_codes_screen.dart';
import '../shared/time/household_clock.dart';
import 'household_route.dart';
import 'nanny_hub_route.dart';

/// Shift-only access' two screens under the hub (nanny-hub ADR-0006): the
/// shifts parents book ahead, and the house codes that open only inside one.
/// The window itself is the household shell's `ShiftPassController`, so the
/// codes close on the same edge the household does.
List<GoRoute> nannyAccessRoutes() => [
  GoRoute(
    path: NannyHubRoute.bookingsPath,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) {
        final view = context.read<HouseholdView>();
        final clock = context.read<HouseholdClock>();
        return BookingsController(
          bookingRepository: context.read<BookingRepository>(),
          shiftDirectory: context.read<ShiftDirectory>(),
          householdId: HouseholdRoute.idFrom(state),
          viewerMemberId: view.viewerMember?.id,
          isFamily: view.permissions.isFamily,
          now: () => clock.now,
        );
      },
      child: const BookingsScreen(),
    ),
  ),
  GoRoute(
    path: NannyHubRoute.codesPath,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) {
        final view = context.read<HouseholdView>();
        return HouseCodesController(
          houseCodeRepository: context.read<HouseCodeRepository>(),
          pass: context.read<ShiftPassController>(),
          householdId: HouseholdRoute.idFrom(state),
          memberId: view.viewerMember?.id,
          isFamily: view.permissions.isFamily,
        );
      },
      child: const HouseCodesScreen(),
    ),
  ),
];
