import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../legal/model/legal_versions.dart';

part 'guardian_consent.freezed.dart';
part 'guardian_consent.g.dart';

/// A parent's consent to NestPrep keeping a child's information, recorded on
/// the child's profile when it is made a child (accounts ADR-0005): which
/// adult gave it, against which version of the privacy policy, and when.
///
/// The rules require one on every `kid` profile a client writes and refuse
/// one that names anybody but the writer; `setChildProfile` records it for a
/// profile marked a child in Family profiles.
@freezed
abstract class GuardianConsent with _$GuardianConsent {
  const factory GuardianConsent({
    required String byMemberId,
    required int version,
    @ServerTimestampConverter() DateTime? at,
  }) = _GuardianConsent;

  const GuardianConsent._();

  /// The consent [byMemberId] gives now, against the privacy policy this
  /// build ships; the server stamps the time.
  factory GuardianConsent.givenBy(String byMemberId) =>
      GuardianConsent(byMemberId: byMemberId, version: LegalVersions.privacy);

  factory GuardianConsent.fromJson(Map<String, Object?> json) =>
      _$GuardianConsentFromJson(json);
}
