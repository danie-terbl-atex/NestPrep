import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/documents/data/document_directory.dart';
import '../features/family_profiles/data/family_profile_repository.dart';
import '../features/household/model/household_view.dart';
import '../features/nanny_hub/data/nanny_hub_repository.dart';
import '../features/nanny_hub/data/photo_picker.dart';
import '../features/nanny_hub/data/photo_store.dart';
import '../features/nanny_hub/data/shift_directory.dart';
import '../features/nanny_hub/data/shift_repository.dart';
import '../features/nanny_hub/state/nanny_hub_controller.dart';
import '../features/nanny_hub/state/photo_library.dart';
import '../features/nanny_hub/state/shift_controller.dart';
import '../features/nanny_hub/ui/checklists_screen.dart';
import '../features/nanny_hub/ui/child_card_screen.dart';
import '../features/nanny_hub/ui/emergency_screen.dart';
import '../features/nanny_hub/ui/house_guide_screen.dart';
import '../features/nanny_hub/ui/house_rules_screen.dart';
import '../features/nanny_hub/ui/nanny_hub_screen.dart';
import '../features/nanny_hub/ui/shift_screen.dart';
import '../features/nanny_hub/ui/shift_summary_screen.dart';
import '../shared/links/external_link_opener.dart';
import 'household_route.dart';
import 'nanny_hub_route.dart';

/// The nanny hub's routes under the household shell (nanny-hub ADR-0003), in
/// their own file so the route table gains one line.
///
/// Every hub screen shares one shell, so they share one controller, one set
/// of listeners and one photo library. The controller follows the household
/// view because a new child, a rename or a changed grant has to reach it.
/// Shift mode adds its own controller, which follows one shift's log.
ShellRoute nannyHubRoutes() => ShellRoute(
  builder: (context, state, child) {
    final householdId = HouseholdRoute.idFrom(state);
    final view = context.read<HouseholdView>();
    return ChangeNotifierProvider(
      create: (context) => PhotoLibrary(
        photoStore: context.read<PhotoStore>(),
        documentDirectory: context.read<DocumentDirectory>(),
        householdId: householdId,
        uploaderUid: view.viewerUid,
      ),
      child: ChangeNotifierProxyProvider<HouseholdView, NannyHubController>(
        create: (context) => NannyHubController(
          nannyHubRepository: context.read<NannyHubRepository>(),
          shiftRepository: context.read<ShiftRepository>(),
          familyProfileRepository: context.read<FamilyProfileRepository>(),
          householdId: householdId,
          household: context.read<HouseholdView>(),
          photos: context.read<PhotoLibrary>(),
          photoPicker: context.read<PhotoPicker>(),
          linkOpener: context.read<ExternalLinkOpener>(),
        ),
        update: (context, view, controller) =>
            controller!..followHousehold(view),
        child: child,
      ),
    );
  },
  routes: [
    GoRoute(
      path: NannyHubRoute.path,
      builder: (context, state) => const NannyHubScreen(),
    ),
    GoRoute(
      path: NannyHubRoute.childPath,
      builder: (context, state) => ChildCardScreen(
        childId: NannyHubRoute.parameterFrom(
          state,
          NannyHubRoute.childParameter,
        ),
      ),
    ),
    GoRoute(
      path: NannyHubRoute.emergencyPath,
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: NannyHubRoute.guidePath,
      builder: (context, state) => const HouseGuideScreen(),
    ),
    GoRoute(
      path: NannyHubRoute.rulesPath,
      builder: (context, state) => const HouseRulesScreen(),
    ),
    GoRoute(
      path: NannyHubRoute.checklistsPath,
      builder: (context, state) => const ChecklistsScreen(),
    ),
    GoRoute(
      path: NannyHubRoute.shiftPath,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => ShiftController(
          shiftRepository: context.read<ShiftRepository>(),
          shiftDirectory: context.read<ShiftDirectory>(),
          photos: context.read<PhotoLibrary>(),
          householdId: HouseholdRoute.idFrom(state),
          shiftId: NannyHubRoute.parameterFrom(
            state,
            NannyHubRoute.shiftParameter,
          ),
          memberId: context.read<HouseholdView>().viewerMember?.id ?? '',
        ),
        child: const ShiftScreen(),
      ),
    ),
    GoRoute(
      path: NannyHubRoute.summaryPath,
      builder: (context, state) => ShiftSummaryScreen(
        shiftId: NannyHubRoute.parameterFrom(
          state,
          NannyHubRoute.shiftParameter,
        ),
      ),
    ),
  ],
);

