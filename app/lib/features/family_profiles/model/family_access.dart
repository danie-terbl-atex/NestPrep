import 'package:flutter/foundation.dart';

import '../../household/model/access_level.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_permissions.dart';
import '../../household/model/household_view.dart';

/// What the viewer may see and change in family profiles — the client's mirror
/// of the family-profiles rules, used only to avoid offering what the rules
/// would refuse (`FE-04`, `BE-20`). The rules are the authority.
///
/// Reading is the household's grant (household ADR-0003, family-profiles
/// ADR-0002): a profile — allergies included — by the `familyProfiles` area,
/// medication by the `medical` area, each at `own` only for the viewer's own
/// member. A person always sees their own. Writing is unchanged from
/// family-profiles ADR-0001: an admin writes anybody's, everybody else their
/// own.
@immutable
class FamilyAccess {
  const FamilyAccess({required this.permissions, required this.viewerMemberId});

  factory FamilyAccess.of(HouseholdView view) => FamilyAccess(
    permissions: view.permissions,
    viewerMemberId: view.viewerMember?.id,
  );

  final HouseholdPermissions permissions;

  /// The profile the viewer claimed, if they claimed one.
  final String? viewerMemberId;

  bool get isAdmin => permissions.isAdmin;

  /// Whose profile `own` means: the rules' `ownMemberId`, or — for an account
  /// claimed before household ADR-0003 — the profile it claimed.
  String? get ownMemberId => permissions.ownMemberId ?? viewerMemberId;

  bool _isSelf(String memberId) =>
      memberId == viewerMemberId || memberId == permissions.ownMemberId;

  /// Whether family profiles appear in the app at all for this viewer.
  bool get isVisible => permissions.canUse(HouseholdArea.familyProfiles);

  /// Every profile in the household; otherwise only their own, and the list
  /// reads exactly that one document (a rule is not a filter).
  bool get seesEveryProfile =>
      permissions.canView(HouseholdArea.familyProfiles);

  bool canSeeProfile(String memberId) => seesEveryProfile || _isSelf(memberId);

  /// Schools are shared by every child at them, so only an admin changes one.
  bool get canManageSchools => isAdmin;

  /// An admin edits anybody's profile; everybody else edits only their own.
  bool canEdit(String memberId) => isAdmin || _isSelf(memberId);

  /// Medication: the `medical` grant, or their own.
  bool canSeeHealth(String memberId) =>
      permissions.canView(HouseholdArea.medical) ||
      (permissions.hasOwnOnly(HouseholdArea.medical) &&
          memberId == permissions.ownMemberId) ||
      _isSelf(memberId);

  bool canEditHealth(String memberId) => canEdit(memberId);

  (bool, AccessLevel, AccessLevel, String?, String?) get _identity => (
    isAdmin,
    permissions.levelIn(HouseholdArea.familyProfiles),
    permissions.levelIn(HouseholdArea.medical),
    permissions.ownMemberId,
    viewerMemberId,
  );

  @override
  bool operator ==(Object other) =>
      other is FamilyAccess && other._identity == _identity;

  @override
  int get hashCode => _identity.hashCode;
}
