import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/firestore/server_timestamp_converter.dart';
import '../../../../shared/recurrence/calendar_date_converter.dart';
import '../../../../shared/recurrence/recurrence_expansion.dart';
import '../../../../shared/recurrence/recurrence_rule.dart';
import '../../../../shared/time/calendar_date.dart';
import '../job_step.dart';
import 'routine_cadence.dart';

part 'room_routine.freezed.dart';
part 'room_routine.g.dart';

/// A recurring checklist for one room and one helper, at
/// `households/{id}/homeCareRoutines/{routineId}` (home-care ADR-0004).
///
/// It repeats by the shared rule (foundation ADR-0005) from [firstDate]; a
/// routine with no rule happens once — a deep clean before visitors. Its items
/// are the same shape as a job's steps, so the same editor writes them and
/// the same tile ticks them.
@freezed
abstract class RoomRoutine with _$RoomRoutine {
  const factory RoomRoutine({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    required String roomId,
    @JsonKey(unknownEnumValue: RoutineCadence.daily)
    required RoutineCadence cadence,
    @Default(<JobStep>[]) List<JobStep> items,

    /// The member profile who does it — claimed or not. What `own` means.
    required String helperId,
    @CalendarDateConverter() required CalendarDate firstDate,
    RecurrenceRule? recurrence,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _RoomRoutine;

  const RoomRoutine._();

  factory RoomRoutine.fromJson(Map<String, Object?> json) =>
      _$RoomRoutineFromJson(json);

  /// What the rules keep: a name's length and how many items one routine
  /// carries; an item is as long as a job's step may be.
  static const nameLimit = 60;
  static const itemLimit = 30;
  static const itemTextLimit = 120;

  /// Whether it falls on [day], by the one expansion todos and the calendar
  /// read too.
  bool fallsOn(CalendarDate day) => expandOccurrences(
    firstDate: firstDate,
    rule: recurrence,
    windowStart: day,
    windowEnd: day,
  ).isNotEmpty;
}
