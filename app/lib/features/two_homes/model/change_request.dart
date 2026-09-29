import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';
import 'custody_schedule.dart';
import 'custody_side.dart';

part 'change_request.freezed.dart';
part 'change_request.g.dart';

/// A swap of some days, or a whole new schedule.
enum ChangeKind { swap, schedule }

/// Where a request is. `closed` is one left waiting when the link ended.
enum RequestStatus { pending, accepted, declined, withdrawn, closed }

/// One home asking the other for a change, at
/// `households/{id}/coParentLinks/{linkId}/requests/{id}` (household
/// ADR-0004). Nothing moves until the other home accepts; answered or not,
/// it stays as the link's history.
@freezed
abstract class ChangeRequest with _$ChangeRequest {
  const factory ChangeRequest({
    @JsonKey(includeToJson: false) required String id,
    @JsonKey(unknownEnumValue: ChangeKind.swap) required ChangeKind kind,

    /// A swap's first and last day, and the home that would have the child.
    @NullableCalendarDateConverter() CalendarDate? from,
    @NullableCalendarDateConverter() CalendarDate? to,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    CustodySide? toSide,

    /// A proposed schedule.
    CustodySchedule? schedule,
    String? note,
    required CustodySide proposedBySide,
    @JsonKey(unknownEnumValue: RequestStatus.closed)
    required RequestStatus status,
    @ServerTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? answeredAt,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    CustodySide? answeredBySide,
    String? answerNote,
  }) = _ChangeRequest;

  const ChangeRequest._();

  factory ChangeRequest.fromJson(Map<String, Object?> json) =>
      _$ChangeRequestFromJson(json);

  bool get isPending => status == RequestStatus.pending;

  /// Days a swap covers, first and last included.
  int get dayCount {
    final start = from;
    final end = to;
    return start == null || end == null ? 0 : start.daysUntil(end) + 1;
  }

  /// The longest a single swap may be; longer is a new schedule.
  static const maxSwapDays = 14;
  static const maxNoteLength = 300;
}
