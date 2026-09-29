import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'house_rule.freezed.dart';
part 'house_rule.g.dart';

/// One of the house's rules for whoever looks after the children — "No
/// screens after six", "Sweets only on Fridays" — at
/// `households/{id}/nannyRules/{id}`.
@freezed
abstract class HouseRule with _$HouseRule {
  const factory HouseRule({
    @JsonKey(includeToJson: false) required String id,
    required String text,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _HouseRule;

  factory HouseRule.fromJson(Map<String, Object?> json) =>
      _$HouseRuleFromJson(json);
}
