import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';

part 'kid_routine_tick.freezed.dart';
part 'kid_routine_tick.g.dart';

/// One child's steps done on one day of one routine, at
/// `households/{id}/kidRoutineTicks/{routineId}_{kidId}_{date}`
/// (kid-routines ADR-0001).
@freezed
abstract class KidRoutineTick with _$KidRoutineTick {
  const factory KidRoutineTick({
    required String routineId,
    required String kidId,
    @CalendarDateConverter() required CalendarDate occurrenceDate,
    @Default(<String>[]) List<String> doneStepIds,
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _KidRoutineTick;

  const KidRoutineTick._();

  factory KidRoutineTick.fromJson(Map<String, Object?> json) =>
      _$KidRoutineTickFromJson(json);

  /// The id the rules hold a tick to.
  static String idFor({
    required String routineId,
    required String kidId,
    required CalendarDate date,
  }) => '${routineId}_${kidId}_${date.iso}';

  String get id =>
      idFor(routineId: routineId, kidId: kidId, date: occurrenceDate);
}
