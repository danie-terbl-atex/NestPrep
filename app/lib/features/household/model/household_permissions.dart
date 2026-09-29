import 'access_defaults.dart';
import 'access_grant.dart';
import 'access_level.dart';
import 'household.dart';
import 'household_area.dart';
import 'member.dart';
import 'member_role.dart';

/// What the signed-in account may see and do in this household, area by area
/// (household ADR-0003) — the client's copy of the rules' `canView`,
/// `canEdit` and `hasOwnOnly`, so the app hides what a role cannot use.
///
/// **It decides nothing.** `firestore.rules` and `storage.rules` enforce every
/// one of these answers; this exists so a helper is not shown a button the
/// server will refuse (`FE-04`, `BE-20`). When the two disagree, the server is
/// right and this is the bug.
///
/// Feature screens read it off `HouseholdView.permissions`:
///
/// ```dart
/// final permissions = context.watch<HouseholdView>().permissions;
/// if (permissions.canEdit(HouseholdArea.groceries)) ...
/// ```
final class HouseholdPermissions {
  const HouseholdPermissions._({
    required this.role,
    required this._grant,
    required this.ownMemberId,
  });

  /// Read from the household document the rules read, for one account.
  factory HouseholdPermissions.of(Household household, String uid) {
    final role = household.roleOf(uid);
    return HouseholdPermissions._(
      role: role,
      grant: household.access[uid] ?? _withoutGrant(household, uid, role),
      ownMemberId: household.profiles[uid],
    );
  }

  /// What a profile nobody has claimed will hold once somebody does: its own
  /// stored choice, or its role's defaults — what `redeemInvite` records.
  factory HouseholdPermissions.unclaimed(Member member) =>
      HouseholdPermissions._(
        role: member.role,
        grant: member.role.isFamily
            ? null
            : member.access ?? AccessDefaults.forRole(member.role),
        ownMemberId: member.id,
      );

  /// What a kid device may see and do (accounts ADR-0004): the grant its kid
  /// profile holds, and nothing when that profile is no longer a kid or holds
  /// no grant — the rules' `kidDeviceLevelIn`, read off the profile the device
  /// already watches.
  factory HouseholdPermissions.kidDevice(Member profile) =>
      HouseholdPermissions._(
        role: MemberRole.kid,
        grant: profile.role == MemberRole.kid
            ? profile.access ?? AccessGrant.uniform(AccessLevel.none)
            : AccessGrant.uniform(AccessLevel.none),
        ownMemberId: profile.id,
      );

  /// Everything, as family sees it — what a screen shows when nothing says
  /// otherwise.
  static const family = HouseholdPermissions._(
    role: MemberRole.admin,
    grant: null,
    ownMemberId: null,
  );

  /// Null for an account that is not in the household at all.
  final MemberRole? role;

  /// The profile this account claimed, which `own` means.
  final String? ownMemberId;

  final AccessGrant? _grant;

  /// The grant as it stands, for the editor to start from. Null for family.
  AccessGrant? get grant => isFamily ? null : _grant;

  /// A helper claimed before ADR-0003 has no grant and keeps what every
  /// helper had; a kid or carer with none has nothing — as the rules do.
  static AccessGrant? _withoutGrant(
    Household household,
    String uid,
    MemberRole? role,
  ) {
    if (role == null || role.isFamily) return null;
    final storedName = household.members[uid];
    return storedName == MemberRole.helper.name
        ? AccessDefaults.legacyHelper
        : AccessGrant.uniform(AccessLevel.none);
  }

  bool get isMember => role != null;

  bool get isFamily => role?.isFamily ?? false;

  bool get isAdmin => role?.isAdmin ?? false;

  AccessLevel levelIn(HouseholdArea area) {
    if (!isMember) return AccessLevel.none;
    if (isFamily) return AccessLevel.edit;
    return _grant?.levelIn(area) ?? AccessLevel.none;
  }

  /// Reads everything in the area.
  bool canView(HouseholdArea area) => levelIn(area).seesEverything;

  /// Adds and changes, as family does.
  bool canEdit(HouseholdArea area) => levelIn(area) == AccessLevel.edit;

  /// Sees only what is theirs, and must ask for exactly that.
  bool hasOwnOnly(HouseholdArea area) => levelIn(area) == AccessLevel.own;

  /// Anything at all — whether the area appears in the app for them.
  bool canUse(HouseholdArea area) => levelIn(area).isAnything;
}
