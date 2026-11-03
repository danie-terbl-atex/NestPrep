import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import 'assistant_via.dart';

part 'assistant_activity.freezed.dart';
part 'assistant_activity.g.dart';

/// One change an assistant made, at `households/{id}/assistantActivity/{id}`
/// (assistants ADR-0005): which connection, as whom, and which tool — ids
/// only, never what was written. A Function writes it in the same
/// transaction as the change, and it expires after ninety days.
@freezed
abstract class AssistantActivity with _$AssistantActivity {
  const factory AssistantActivity({
    @JsonKey(includeToJson: false) required String id,
    required String grantId,
    required String memberId,
    @JsonKey(unknownEnumValue: AssistantVia.assistant)
    @Default(AssistantVia.assistant)
    AssistantVia via,
    required String tool,
    @NullableTimestampConverter() DateTime? at,
  }) = _AssistantActivity;

  factory AssistantActivity.fromJson(Map<String, Object?> json) =>
      _$AssistantActivityFromJson(json);
}
