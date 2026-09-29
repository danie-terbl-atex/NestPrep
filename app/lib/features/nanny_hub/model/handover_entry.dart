import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/instant_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import 'handover_kind.dart';
import 'handover_mood.dart';

part 'handover_entry.freezed.dart';
part 'handover_entry.g.dart';

/// One line of the handover log, at
/// `households/{id}/nannyShifts/{shiftId}/entries/{id}`: what happened, to
/// which children, when, with a photo if there is one (nanny-hub ADR-0002).
///
/// [at] is when it happened, which the carer may set back — a nap is logged
/// when it ends — and never forward; [createdAt] is when it was written, which
/// only the server says.
@freezed
abstract class HandoverEntry with _$HandoverEntry {
  const factory HandoverEntry({
    @JsonKey(includeToJson: false) required String id,
    @JsonKey(unknownEnumValue: HandoverKind.note) required HandoverKind kind,
    String? note,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    HandoverMood? mood,
    @Default(<String>[]) List<String> childIds,
    String? photoId,
    @InstantConverter() required DateTime at,
    required String byMemberId,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _HandoverEntry;

  factory HandoverEntry.fromJson(Map<String, Object?> json) =>
      _$HandoverEntryFromJson(json);
}
