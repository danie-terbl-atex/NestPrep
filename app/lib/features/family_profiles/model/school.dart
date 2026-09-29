import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'school.freezed.dart';
part 'school.g.dart';

/// A school somebody in the household goes to, at
/// `households/{id}/schools/{schoolId}` (family-profiles ADR-0001).
///
/// A household entity rather than text on each child, so two siblings at one
/// school share its rules: marking it nut-free once is a rule for both, and
/// there is one place for what lunch-box will want next (term dates).
@freezed
abstract class School with _$School {
  const factory School({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    @Default(false) bool nutFree,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _School;

  factory School.fromJson(Map<String, Object?> json) => _$SchoolFromJson(json);
}
