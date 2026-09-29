import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';
import 'pickup_collector.dart';

part 'pickup_change.freezed.dart';
part 'pickup_change.g.dart';

/// One day that is not like the week — Gogo collects on Thursday the 9th, or
/// there is no school run at all — at
/// `households/{id}/nannyPickupChanges/{childId}_{YYYY-MM-DD}` (nanny-hub
/// ADR-0005). It wins over the weekday's run for that child on that date.
///
/// Both collector ids null means nobody collects that day.
@freezed
abstract class PickupChange with _$PickupChange {
  const factory PickupChange({
    @JsonKey(includeToJson: false) required String id,
    required String childId,
    @CalendarDateConverter() required CalendarDate date,
    String? personId,
    String? memberId,
    int? atMinute,
    String? note,
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _PickupChange;

  const PickupChange._();

  factory PickupChange.fromJson(Map<String, Object?> json) =>
      _$PickupChangeFromJson(json);

  static String idFor(String childId, CalendarDate date) =>
      '${childId}_${date.iso}';

  PickupCollector get collector =>
      PickupCollector.from(personId: personId, memberId: memberId);
}
