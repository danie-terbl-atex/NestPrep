import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'pickup_collector.dart';

part 'school_run.freezed.dart';
part 'school_run.g.dart';

/// Who collects one child on one weekday, every week, at
/// `households/{id}/nannySchoolRuns/{childId}_{weekday}` (nanny-hub ADR-0005).
/// The id is the pair, so a child has at most one run per weekday and there is
/// no field to point it at another child.
///
/// The collector is exactly one of a listed pickup person ([personId]) or a
/// household member ([memberId]) — the nanny herself, or a parent.
@freezed
abstract class SchoolRun with _$SchoolRun {
  const factory SchoolRun({
    @JsonKey(includeToJson: false) required String id,
    required String childId,

    /// ISO weekday: Monday is 1, Sunday is 7.
    required int weekday,
    String? personId,
    String? memberId,

    /// The wall-clock minute in the household's zone (`ENG-21`).
    int? atMinute,

    /// "Oakwood Primary, the side gate".
    String? place,
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _SchoolRun;

  const SchoolRun._();

  factory SchoolRun.fromJson(Map<String, Object?> json) =>
      _$SchoolRunFromJson(json);

  static String idFor(String childId, int weekday) => '${childId}_$weekday';

  PickupCollector get collector =>
      PickupCollector.from(personId: personId, memberId: memberId);
}
