import '../design/gallery/design_gallery_screen.dart';
import '../features/accounts/model/session.dart';
import '../features/accounts/state/session_controller.dart';
import '../features/accounts/ui/forgot_password_screen.dart';
import '../features/accounts/ui/register_screen.dart';
import '../features/accounts/ui/session_gate_screen.dart';
import '../features/accounts/ui/sign_in_screen.dart';
import '../features/household/ui/household_gate_screen.dart';
import '../features/household/ui/join_invite_screen.dart';
import '../features/legal/ui/consent_screen.dart';
import '../shared/async/async_state.dart';
import 'account_routes.dart';
import 'design_gallery_access.dart';
import 'household_route.dart';
import 'kid_routes.dart';
import 'legal_routes.dart';

/// Where a caller in this session belongs, or null to leave them where they are.
///
/// Signed out, only the three ways in exist; signed in with an address nobody
/// has proved and no household, only the confirm screen; signed in with no
/// household, only the gate; signed in with one, everything under it. The design
/// gallery is exempt because it renders no data and debug builds use it before
/// sign-in. The router's `redirect`; tested on its own.
String? redirectForSession(
  SessionController session,
  String location, {
  String? pendingInviteCode,
}) {
  if (DesignGalleryAccess.isAvailable && location == DesignGalleryScreen.path) {
    return null;
  }

  final state = session.session;
  if (state is! AsyncData<Session>) {
    return location == SessionGateScreen.path ? null : SessionGateScreen.path;
  }
  if (state.value is SignedOut) {
    const waysIn = [
      SignInScreen.path,
      RegisterScreen.path,
      ForgotPasswordScreen.path,
      KidRoute.codePath,
    ];
    return waysIn.contains(location) ? null : SignInScreen.path;
  }
  // A kid device has one screen (accounts ADR-0003).
  if (state.value is KidSignedIn) return redirectForKid(location);

  // ---- account data (accounts ADR-0006) ----
  // The account centre — download, delete, the legal pages — is open to any
  // signed-in person whatever else is unfinished: no household, terms not yet
  // agreed. Somebody who will not agree to new
  // terms must still be able to delete their account.
  if (isAccountLocation(location)) return null;

  // ---- consent (accounts ADR-0005) ----
  // Nothing else opens until this account has agreed to the terms and the
  // privacy policy this build ships; the two documents, About and the
  // licences stay readable meanwhile.
  if (session.needsLegalConsent) return redirectForConsent(location);

  if (pendingInviteCode != null) {
    return location == JoinInviteScreen.path ? null : JoinInviteScreen.path;
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
    RegisterScreen.path,
    ForgotPasswordScreen.path,
    HouseholdGateScreen.path,
    JoinInviteScreen.path,
    // Agreed, so the consent step is behind them (accounts ADR-0005).
    ConsentScreen.path,
  ];
  if (waitingRooms.contains(location)) {
    return HouseholdRoute.homeFor(householdId);
  }

  // A household route for a household this account no longer belongs to — it
  // was left on another device, or the link is somebody else's.
  if (location.startsWith('/households/') &&
      !location.startsWith('/households/$householdId/')) {
    return HouseholdRoute.homeFor(householdId);
  }
  return null;
}
