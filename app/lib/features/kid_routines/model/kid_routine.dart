import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import 'kid_routine_slot.dart';
import 'kid_routine_step.dart';

part 'kid_routine.freezed.dart';
part 'kid_routine.g.dart';

/// A child's morning, afternoon or bedtime run of picture steps, at
/// `households/{id}/kidRoutines/{routineId}` (kid-routines ADR-0001).
///
/// One routine may name several children; each ticks their own day. It
/// repeats by the shared rule (foundation ADR-0005) from [firstDate].
@freezed
abstract class KidRoutine with _$KidRoutine {
  const factory KidRoutine({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    @JsonKey(unknownEnumValue: KidRoutineSlot.morning)
    required KidRoutineSlot slot,
    @Default(<String>[]) List<String> kidIds,
    @CalendarDateConverter() required CalendarDate firstDate,
    RecurrenceRule? recurrence,

    /// Minutes since midnight on the household's clock, or null for no time.
    int? finishBy,

    /// Stars for finishing the whole routine.
    @Default(0) int points,
    @Default(<KidRoutineStep>[]) List<KidRoutineStep> steps,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _KidRoutine;

  factory KidRoutine.fromJson(Map<String, Object?> json) =>
      _$KidRoutineFromJson(json);

  /// What the rules keep.
  static const nameLimit = 40;
  static const kidLimit = 12;
  static const stepLimit = 12;
  static const stepTitleLimit = 40;
  static const noteLimit = 120;
  static const partLimit = 8;
  static const partTextLimit = 40;
  static const maxPoints = 20;
}
