import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/time/household_clock.dart';
import '../../documents/data/document_directory.dart';
import '../../family_profiles/model/family_access.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member_role.dart';
import '../data/booking_repository.dart';
import '../data/cache_warmer.dart';
import '../data/offline_shelf.dart';
import '../data/photo_store.dart';
import '../state/offline_keeper.dart';
import '../state/shift_pass_controller.dart';
import 'shift_gate.dart';

/// What the nanny hub keeps running for the whole household, around every
/// screen in it (nanny-hub ADR-0006, ADR-0007):
///
/// - the viewer's **booked-shift window**, which a carer kept to their shifts
///   sees the household through, and which opens the house codes; and
/// - the **offline keeper**, which saves the emergency sheet, the child cards
///   and their photos for no signal when the app opens and whenever a shift
///   starts.
///
/// Both are created once per household and viewer; family and a viewer the hub
/// is not shared with get the window "always open" and nothing saved unasked.
class CarerScope extends StatelessWidget {
  const CarerScope({required this.child, super.key});

  final Widget child;

  static WarmRequest warmRequestFor(HouseholdView view) {
    final family = FamilyAccess.of(view);
    return (
      householdId: view.household.id,
      readsProfiles: family.seesEveryProfile,
      healthOf: [
        for (final member in view.members)
          if (member.role == MemberRole.kid && family.canSeeHealth(member.id))
            member.id,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    final permissions = view.permissions;
    final memberId = view.viewerMember?.id;
    final clock = context.read<HouseholdClock>();
    final readsHub =
        permissions.canView(HouseholdArea.nannyHub) || view.viewerIsShiftOnly;
    final savesOffline =
        readsHub &&
        context.watch<FeatureFlagsController>().isOn(FeatureFlag.nannyOffline);
    return KeyedSubtree(
      key: ValueKey((
        view.household.id,
        memberId,
        permissions.isFamily,
        readsHub,
        view.viewerIsShiftOnly,
      )),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => ShiftPassController(
              bookingRepository: context.read<BookingRepository>(),
              householdId: view.household.id,
              memberId: memberId,
              isFamily: permissions.isFamily || !readsHub,
              now: () => clock.now,
            ),
          ),
          ChangeNotifierProxyProvider<HouseholdView, OfflineKeeper>(
            create: (context) => OfflineKeeper(
              cacheWarmer: context.read<CacheWarmer>(),
              shelf: context.read<OfflineShelf>(),
              photoStore: context.read<PhotoStore>(),
              documentDirectory: context.read<DocumentDirectory>(),
              householdId: view.household.id,
              request: warmRequestFor(view),
              now: () => clock.now,
            ),
            update: (context, view, keeper) =>
                keeper!..follow(warmRequestFor(view)),
          ),
        ],
        child: ShiftGate(
          isShiftOnly: view.viewerIsShiftOnly,
          followsWindow:
              view.viewerIsShiftOnly || (savesOffline && !permissions.isFamily),
          savesOffline: savesOffline,
          savesOnOpen: savesOffline && !permissions.isFamily,
          child: child,
        ),
      ),
    );
  }
}
