import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'access_grant.dart';
import 'access_grant_converter.dart';
import 'member_role.dart';

part 'household.freezed.dart';
part 'household.g.dart';

/// The household document (household ADR-0001). `members` is the uid→role map
/// every Security Rule reads and only a Cloud Function writes — it is the one
/// lookup that answers "is the caller a member, and with what role"
/// (foundation ADR-0002).
@freezed
abstract class Household with _$Household {
  const factory Household({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    required String timeZone,
    @Default(<String, String>{}) Map<String, String> members,

    /// uid → the grant a kid, helper or carer holds, and uid → the profile
    /// that uid claimed (household ADR-0003). Both written only by Functions.
    ///
    /// Never written by the client, so never serialised (household ADR-0002).
    @JsonKey(includeToJson: false)
    @GrantsByUidConverter()
    @Default(<String, AccessGrant>{})
    Map<String, AccessGrant> access,
    @JsonKey(includeToJson: false)
    @Default(<String, String>{})
    Map<String, String> profiles,

    /// `invitePeople` while a new household's admin has not yet finished or
    /// skipped the invite step (household ADR-0003).
    @JsonKey(includeToJson: false) String? pendingSetupStep,
    String? createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _Household;

  const Household._();

  factory Household.fromJson(Map<String, Object?> json) =>
      _$HouseholdFromJson(json);

  /// Where a household is until somebody changes it (household ADR-0001).
  static const defaultTimeZone = 'Africa/Johannesburg';

  MemberRole? roleOf(String uid) {
    final name = members[uid];
    return name == null ? null : MemberRole.fromName(name);
  }

  bool isAdmin(String uid) => roleOf(uid)?.isAdmin ?? false;

  /// The one setup step there is: inviting the people who share the house.
  static const invitePeopleStep = 'invitePeople';

  bool get isWaitingOnInviteStep => pendingSetupStep == invitePeopleStep;

  int get claimedMemberCount => members.length;
}
