import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import 'access_grant.dart';
import 'access_grant_converter.dart';
import 'birthday.dart';
import 'birthday_converter.dart';
import 'guardian_consent.dart';
import 'member_color_converter.dart';
import 'member_role.dart';

part 'member.freezed.dart';
part 'member.g.dart';

/// A household profile at `households/{id}/members/{memberId}` (household
/// ADR-0001). It exists whether or not anyone signs in as it: an admin can
/// schedule for it, assign to it and complete on its behalf.
///
/// `claimedBy` is written only by `redeemInvite` and the detach that leaving or
/// being removed performs — never by a client (household ADR-0002).
@freezed
abstract class Member with _$Member {
  const factory Member({
    @JsonKey(includeToJson: false) required String id,
    required String displayName,
    @MemberColorConverter() required MemberColor color,
    @JsonKey(name: 'role') required String roleName,

    /// Optional, and optional again inside: a household that does not know the
    /// year stores the day and the month alone (birthdays ADR-0001).
    @BirthdayConverter() Birthday? birthday,

    /// What a parent chose for a kid, helper or carer (household ADR-0003).
    /// Written with the profile, and afterwards only through
    /// `setMemberAccess`; ignored for family.
    @AccessGrantConverter() AccessGrant? access,
    String? claimedBy,
    @ServerTimestampConverter() DateTime? createdAt,

    /// A parent's consent, on a child's profile (accounts ADR-0005). Absent
    /// on every adult, and on every child profile made before it existed.
    @JsonKey(includeIfNull: false) GuardianConsent? guardianConsent,
  }) = _Member;

  const Member._();

  factory Member.fromJson(Map<String, Object?> json) => _$MemberFromJson(json);

  MemberRole get role => MemberRole.fromName(roleName);

  bool get isClaimed => claimedBy != null;

  /// Whether a parent has consented to this child's information being kept.
  bool get hasGuardianConsent => guardianConsent != null;

  bool isClaimedBy(String uid) => claimedBy == uid;

  static String _firstLetter(String word) =>
      String.fromCharCode(word.runes.first).toUpperCase();

  /// The one or two letters shown on an avatar. Colour is never the only signal
  /// that says who a thing is for (`FE-13`).
  String get initials {
    final words = displayName.trim().split(RegExp(r'\s+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return _firstLetter(words.first);
    return _firstLetter(words.first) + _firstLetter(words.last);
  }
}
