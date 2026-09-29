import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';

part 'point_claim.freezed.dart';
part 'point_claim.g.dart';

/// Where a starred chore's stars are (todos ADR-0003).
enum ClaimStatus {
  /// Waiting for a parent to look.
  pending,

  /// Paid.
  awarded,

  /// A parent asked for another go; the chore is undone again.
  sentBack,

  /// Unticked, so nothing is owed.
  withdrawn,
}

/// One starred completion's claim, at `households/{id}/pointClaims/{taskId}_{date}`
/// — keyed like the completion it is about (todos ADR-0002, ADR-0003). Written
/// only by Functions; the title and stars are the chore's *as they were* when
/// it was ticked, which is what the child was promised.
@freezed
abstract class PointClaim with _$PointClaim {
  const factory PointClaim({
    @JsonKey(includeToJson: false) required String id,
    required String memberId,
    required String taskId,
    @CalendarDateConverter() required CalendarDate occurrenceDate,
    required String title,
    required int points,

    /// A status a newer build wrote reads as withdrawn: owed nothing, shown
    /// nothing (`BE-10`).
    @JsonKey(unknownEnumValue: ClaimStatus.withdrawn)
    required ClaimStatus status,
    @Default(1) int round,
    @NullableTimestampConverter() DateTime? claimedAt,
  }) = _PointClaim;

  const PointClaim._();

  factory PointClaim.fromJson(Map<String, Object?> json) =>
      _$PointClaimFromJson(json);

  bool get isPending => status == ClaimStatus.pending;
}
