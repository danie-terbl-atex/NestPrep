import '../../household/model/household_area.dart';
import '../../household/model/household_permissions.dart';
import 'notification_vocabulary.dart';

/// What a person's digest can hold, in words for the settings screen
/// (notifications ADR-0002). It explains; it decides nothing — the server
/// composes the digest from the same grant, and the rules are what hold it
/// (`FE-04`).
List<DigestSectionKind> digestCoverage(HouseholdPermissions permissions) => [
  if (permissions.canView(HouseholdArea.calendar)) DigestSectionKind.events,
  if (permissions.canUse(HouseholdArea.lunch) ||
      permissions.canView(HouseholdArea.calendar))
    DigestSectionKind.pack,
  if (permissions.canUse(HouseholdArea.todos)) DigestSectionKind.chores,
  if (permissions.canView(HouseholdArea.documents) || permissions.isFamily)
    DigestSectionKind.documents,
  if (permissions.canView(HouseholdArea.nannyHub)) DigestSectionKind.shift,
  if (permissions.isFamily) DigestSectionKind.approvals,
];
