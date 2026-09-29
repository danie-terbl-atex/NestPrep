import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/time/calendar_date.dart';

part 'lunch_packed_day.freezed.dart';
part 'lunch_packed_day.g.dart';

/// That one child's box for one day was packed, at
/// `households/{id}/lunchPacked/{childId}_{YYYY-MM-DD}` (lunch-box
/// ADR-0006). Written in the same batch that takes what was in it out of the
/// pantry, and never changed afterwards, so the same box cannot use the
/// pantry up twice. Deleting it is *undo*, which gives the portions back.
@freezed
abstract class LunchPackedDay with _$LunchPackedDay {
  const factory LunchPackedDay({
    @JsonKey(includeToJson: false) required String id,
    required String childId,

    /// `YYYY-MM-DD` — also the tail of the id.
    required String date,

    /// `YYYY-Www`, which the pantry's listener reads a week by.
    required String week,

    /// The items taken out of the pantry — what the undo gives back.
    @Default(<String>[]) List<String> itemIds,
    required String by,
    @ServerTimestampConverter() DateTime? at,
  }) = _LunchPackedDay;

  const LunchPackedDay._();

  factory LunchPackedDay.fromJson(Map<String, Object?> json) =>
      _$LunchPackedDayFromJson(json);

  static String idFor(String childId, CalendarDate date) =>
      '${childId}_${date.iso}';
}
