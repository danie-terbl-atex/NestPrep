import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'vault_grant.freezed.dart';
part 'vault_grant.g.dart';

/// Somebody allowed to read a vault that is not theirs, at
/// `households/{h}/vaults/{memberId}/grants/{granteeUid}` (documents ADR-0002).
///
/// Keyed by the grantee's account because that is what the rules know; the
/// rules also check that account is the claimant of `memberId`. A grant is
/// read-only access, and revoking it is deleting it.
@freezed
abstract class VaultGrant with _$VaultGrant {
  const factory VaultGrant({
    /// The grantee's uid — the document id.
    @JsonKey(includeToJson: false) required String id,

    /// The grantee's member profile.
    required String memberId,

    /// The member who granted it.
    required String grantedBy,
    @ServerTimestampConverter() DateTime? grantedAt,
  }) = _VaultGrant;

  const VaultGrant._();

  factory VaultGrant.fromJson(Map<String, Object?> json) =>
      _$VaultGrantFromJson(json);

  String get granteeUid => id;
}
