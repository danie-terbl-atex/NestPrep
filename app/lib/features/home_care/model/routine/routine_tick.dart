import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/firestore/server_timestamp_converter.dart';
import '../../../../shared/recurrence/calendar_date_converter.dart';
import '../../../../shared/time/calendar_date.dart';

part 'routine_tick.freezed.dart';
part 'routine_tick.g.dart';

/// One day of one room routine: the items done, at
/// `households/{id}/homeCareRoutineTicks/{routineId}_{date}` — flat under the
/// household, so "what is done this week" is one bounded listener (home-care
/// ADR-0004, todos ADR-0002).
///
/// The id is derived from the routine and the day, so ticking the same day
/// twice writes the same document and changes nothing (`BE-06`).
@freezed
abstract class RoutineTick with _$RoutineTick {
  const factory RoutineTick({
    @JsonKey(includeToJson: false) required String id,
    required String routineId,
    @CalendarDateConverter() required CalendarDate occurrenceDate,

    /// The routine's helper on the day — what `own` reads it by.
    required String helperId,
    @Default(<String>[]) List<String> doneItemIds,

    /// The member who last changed it — the helper, or family on her behalf.
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _RoutineTick;

  factory RoutineTick.fromJson(Map<String, Object?> json) =>
      _$RoutineTickFromJson(json);

  /// The document id for one day of one routine (`BE-06`).
  static String idFor(String routineId, CalendarDate day) =>
      '${routineId}_${day.iso}';
}
