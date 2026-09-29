import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import 'documents_route.dart';
import 'family_route.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'lunch_route.dart';

/// Where somebody belongs inside a household, given who they are there, or
/// null to leave them where they are (household ADR-0003).
///
/// The session redirect cannot answer this — it runs before the household has
/// loaded — so the household shell asks it once the household is in hand:
///
/// - a new household's admin is taken to the invite step until they finish or
///   skip it, and only an admin — who can invite — is ever on it;
/// - a place the person may not use sends them to the first tab they may,
///   or to the household screen when a grant opens none of the four.
///
/// It only moves the screen. The rules are what refuse the data (`FE-04`).
String? householdPlaceRedirect({
  required String location,
  required HouseholdView view,
}) {
  final householdId = view.household.id;
  final setupPath = HouseholdRoute.setupPathFor(householdId);

  final owesInviteStep =
      view.viewerIsAdmin && view.household.isWaitingOnInviteStep;
  if (owesInviteStep) return location == setupPath ? null : setupPath;
  // After the step, the same screen is how an admin invites anybody; it is
  // no place for somebody who cannot invite.
  if (location == setupPath) {
    return view.viewerIsAdmin ? null : firstPlaceFor(view);
  }

  final area = _areaAt(location, householdId);
  if (area == null || view.permissions.canUse(area)) return null;
  return firstPlaceFor(view);
}

/// The first tab this person may use, or the household screen — the one place
/// everybody in a household can always reach.
String firstPlaceFor(HouseholdView view) {
  final householdId = view.household.id;
  for (final tab in HouseholdTab.values) {
    if (view.permissions.canUse(tab.area)) {
      return HouseholdRoute.pathFor(householdId, tab);
    }
  }
  return HouseholdRoute.householdPathFor(householdId);
}

HouseholdArea? _areaAt(String location, String householdId) {
  for (final tab in HouseholdTab.values) {
    if (location == HouseholdRoute.pathFor(householdId, tab)) return tab.area;
  }
  if (location.startsWith(DocumentsRoute.pathFor(householdId))) {
    return HouseholdArea.documents;
  }
  // Family profiles (family-profiles ADR-0002): a deep link is no way round
  // a grant of `none`.
  if (location.startsWith(FamilyRoute.pathFor(householdId))) {
    return HouseholdArea.familyProfiles;
  }
  // Lunch's prep list and library (lunch-box ADR-0004).
  if (location.startsWith(LunchRoute.pathFor(householdId))) {
    return HouseholdArea.lunch;
  }
  return null;
}
