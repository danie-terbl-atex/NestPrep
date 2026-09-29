import 'package:flutter/foundation.dart';

import '../../family_profiles/model/family_access.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';

/// What the viewer may see and do in the nanny hub — the client's mirror of
/// `nanny_hub.rules`, used only so nobody is offered what the rules would
/// refuse (`FE-04`, `BE-20`). The rules are the authority.
///
/// The hub is one area, `nannyHub` (household ADR-0003): `view` reads it,
/// `edit` writes it — a parent authoring, a carer logging a shift
/// (nanny-hub ADR-0003). What it shows of a child's allergies and medication
/// is family profiles' to decide, through `FamilyAccess`, because that is
/// where they live.
@immutable
class NannyAccess {
  const NannyAccess({
    required this.canView,
    required this.canEdit,
    required this.isFamily,
    required this.family,
    required this.viewerMemberId,
    required this.viewerUid,
  });

  factory NannyAccess.of(HouseholdView view) => NannyAccess(
    canView: view.permissions.canView(HouseholdArea.nannyHub),
    canEdit: view.permissions.canEdit(HouseholdArea.nannyHub),
    isFamily: view.permissions.isFamily,
    family: FamilyAccess.of(view),
    viewerMemberId: view.viewerMember?.id,
    viewerUid: view.viewerUid,
  );

  /// Reads the hub — and so whether it appears in the app at all.
  final bool canView;

  /// Writes the hub: authors cards, the sheet, the guide, the rules and the
  /// checklists; starts, logs and ends shifts.
  final bool canEdit;

  /// Family starts and ends a shift for somebody else; everybody else only
  /// their own (nanny-hub ADR-0002).
  final bool isFamily;

  final FamilyAccess family;

  /// The profile the viewer claimed: what everything they write is stamped
  /// with, and whose shift is theirs.
  final String? viewerMemberId;

  /// Storage rules know accounts, not profiles, so a photo is stamped with it.
  final String viewerUid;

  /// Allergies live in a child's family profile, read by the
  /// `familyProfiles` grant (family-profiles ADR-0002).
  bool canSeeAllergiesOf(String memberId) => family.canSeeProfile(memberId);

  /// Medication is behind the `medical` grant.
  bool canSeeMedicationOf(String memberId) => family.canSeeHealth(memberId);

  bool mayEndShiftOf(String carerMemberId) =>
      canEdit && (isFamily || carerMemberId == viewerMemberId);

  (bool, bool, bool, FamilyAccess, String?, String) get _identity => (
    canView,
    canEdit,
    isFamily,
    family,
    viewerMemberId,
    viewerUid,
  );

  @override
  bool operator ==(Object other) =>
      other is NannyAccess && other._identity == _identity;

  @override
  int get hashCode => _identity.hashCode;
}
