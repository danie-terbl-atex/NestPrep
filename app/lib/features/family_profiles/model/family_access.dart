import 'package:flutter/foundation.dart';

import '../../household/model/household_view.dart';
import '../../household/model/member_role.dart';

/// What the viewer may see and change in family profiles — the client's mirror
/// of `firestore.rules`, used only to avoid offering what the rules would
/// refuse (`FE-04`, `BE-20`). The rules are the authority.
///
/// `canSeeHealth` is the seam household phase 2 widens: a helper or carer the
/// household grants health access joins here, and in `mayReadHealth` in the
/// rules, and nowhere else (family-profiles ADR-0001).
@immutable
class FamilyAccess {
  const FamilyAccess({required this.viewerRole, required this.viewerMemberId});

  factory FamilyAccess.of(HouseholdView view) => FamilyAccess(
    viewerRole: view.viewerRole,
    viewerMemberId: view.viewerMember?.id,
  );

  final MemberRole? viewerRole;

  /// The profile the viewer claimed, if they claimed one.
  final String? viewerMemberId;

  bool get isAdmin => viewerRole == MemberRole.admin;

  bool _isSelf(String memberId) => memberId == viewerMemberId;

  /// Schools are shared by every child at them, so only an admin changes one.
  bool get canManageSchools => isAdmin;

  /// An admin edits anybody's profile; everybody else edits only their own.
  bool canEdit(String memberId) => isAdmin || _isSelf(memberId);

  /// Medication: an admin, a `member`, and the person themselves. Not a helper
  /// — until household phase 2 says a household granted it.
  bool canSeeHealth(String memberId) =>
      isAdmin || viewerRole == MemberRole.member || _isSelf(memberId);

  bool canEditHealth(String memberId) => canEdit(memberId);

  @override
  bool operator ==(Object other) =>
      other is FamilyAccess &&
      other.viewerRole == viewerRole &&
      other.viewerMemberId == viewerMemberId;

  @override
  int get hashCode => Object.hash(viewerRole, viewerMemberId);
}
