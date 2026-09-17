import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';

part 'household_event.freezed.dart';
part 'household_event.g.dart';

/// Something on the household's calendar, at `households/{id}/events/{eventId}`
/// (calendar ADR-0001).
///
/// The time is the household's wall clock, not an instant: 07:30 stays 07:30
/// after the clocks change, which is what a school run means (calendar
/// ADR-0002). `startMinute` null is what makes an event all-day.
@freezed
abstract class HouseholdEvent with _$HouseholdEvent {
  const factory HouseholdEvent({
    @JsonKey(includeToJson: false) required String id,
    required String title,
    String? note,

    /// The first occurrence's day, in the household's timezone.
    @CalendarDateConverter() required CalendarDate date,

    /// Minutes since midnight where the household lives. Null on both means
    /// all day.
    int? startMinute,
    int? endMinute,
    RecurrenceRule? recurrence,

    /// The member profiles it is for — a school run is for the child and the
    /// parent driving.
    @Default(<String>[]) List<String> memberIds,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _HouseholdEvent;

  const HouseholdEvent._();

  factory HouseholdEvent.fromJson(Map<String, Object?> json) =>
      _$HouseholdEventFromJson(json);

  bool get isAllDay => startMinute == null;

  bool get isForEveryone => memberIds.isEmpty;

  bool isFor(String memberId) => isForEveryone || memberIds.contains(memberId);

  /// Where a timed event sorts within its day. All-day events come first, which
  /// is what `-1` buys without a second sort key.
  int get sortMinute => startMinute ?? -1;

  /// Minutes from the start to the end. An end before the start is read as the
  /// next morning — a party that runs past midnight (calendar ADR-0002).
  int? get durationMinutes {
    final start = startMinute;
    final end = endMinute;
    if (start == null || end == null) return null;
    return end >= start ? end - start : (minutesInADay - start) + end;
  }

  static const minutesInADay = 24 * 60;
}
