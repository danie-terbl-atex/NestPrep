import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/firestore/server_timestamp_converter.dart';
import 'helper_language.dart';
import 'helper_language_converter.dart';

part 'helper_profile.freezed.dart';
part 'helper_profile.g.dart';

/// A member's home-care profile, at `households/{id}/homeCareHelpers/{memberId}`
/// (home-care ADR-0006): the language her jobs, safety and routines are shown
/// and read aloud in. The id is the member's, so there is one per person.
@freezed
abstract class HelperProfile with _$HelperProfile {
  const factory HelperProfile({
    /// The member profile it belongs to.
    @JsonKey(includeToJson: false) required String id,
    @HelperLanguageConverter() required HelperLanguage language,

    /// Who chose it — she, or family on her behalf.
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _HelperProfile;

  factory HelperProfile.fromJson(Map<String, Object?> json) =>
      _$HelperProfileFromJson(json);
}
