import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/gallery/design_gallery_screen.dart';
import '../features/accounts/model/session.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/accounts/ui/session_gate_screen.dart';
import '../features/accounts/ui/sign_in_screen.dart';
import '../features/household/data/household_directory.dart';
import '../features/household/data/household_repository.dart';
import '../features/household/model/household.dart';
import '../features/household/state/household_controller.dart';
import '../features/household/state/household_gate_controller.dart';
import '../features/household/ui/household_gate_screen.dart';
import '../features/household/ui/household_screen.dart';
import '../shared/async/async_state.dart';
import 'household_route.dart';

/// Every screen is reachable by path, and the household it belongs to is in the
/// path (`FE-17`, foundation ADR-0006). A route creates the controller its
/// screen reads, so the controller's lifetime is the screen's — and switching
/// household is a navigation, which is what drops the old listeners.
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
      path: HouseholdRoute.path,
      name: HouseholdScreen.routeName,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => HouseholdController(
          householdRepository: context.read<HouseholdRepository>(),
          householdDirectory: context.read<HouseholdDirectory>(),
          householdId: HouseholdRoute.idFrom(state),
          viewerUid: session.uidOrEmpty,
        ),
        child: const HouseholdScreen(),
      ),
    ),
    if (kDebugMode)
      GoRoute(
        path: DesignGalleryScreen.path,
        builder: (context, state) => const DesignGalleryScreen(),
      ),
  ],
);

/// Where a caller in this session belongs, or null to leave them where they are.
///
/// Signed out, only the sign-in screen exists; signed in with no household, only
/// the gate; signed in with one, everything under it. The design gallery is
/// exempt because it renders no data and debug builds use it before sign-in.
@visibleForTesting
String? redirectForSession(SessionController session, String location) {
  if (kDebugMode && location == DesignGalleryScreen.path) return null;

  final state = session.session;
  if (state is! AsyncData<Session>) {
    return location == SessionGateScreen.path ? null : SessionGateScreen.path;
  }
  if (state.value is SignedOut) {
    return location == SignInScreen.path ? null : SignInScreen.path;
  }

  final householdId = session.activeHouseholdId;
  if (householdId == null) {
    return location == HouseholdGateScreen.path
        ? null
        : HouseholdGateScreen.path;
  }

  const waitingRooms = [
    SessionGateScreen.path,
    SignInScreen.path,
    HouseholdGateScreen.path,
  ];
  return waitingRooms.contains(location)
      ? HouseholdRoute.pathFor(householdId)
      : null;
}
