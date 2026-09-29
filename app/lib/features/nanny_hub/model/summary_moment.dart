import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/instant_converter.dart';
import 'handover_kind.dart';
import 'handover_mood.dart';

part 'summary_moment.freezed.dart';
part 'summary_moment.g.dart';

/// One line of a shift's summary, as `endNannyShift` copied it from the log.
/// It says whether there was a photo rather than which one, so the summary is
/// a record of the evening and not a second way to the photos.
@freezed
abstract class SummaryMoment with _$SummaryMoment {
  const factory SummaryMoment({
    @JsonKey(unknownEnumValue: HandoverKind.note) required HandoverKind kind,
    @InstantConverter() required DateTime at,
    String? note,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    HandoverMood? mood,
    @Default(<String>[]) List<String> childIds,
    @Default(false) bool hasPhoto,
  }) = _SummaryMoment;

  factory SummaryMoment.fromJson(Map<String, Object?> json) =>
      _$SummaryMomentFromJson(json);
}
