import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';
import 'calendar_provider.dart';

part 'synced_event.freezed.dart';
part 'synced_event.g.dart';

/// One occurrence brought in from a connected calendar, at
/// `households/{id}/syncedEvents/{id}` (calendar ADR-0003).
///
/// Already on the household's wall clock — the Function converted it from the
/// provider's instant, which is what keeps a repeating 07:30 at 07:30 across a
/// clocks change (calendar ADR-0002). It is read-only here: it is changed in
/// the calendar it came from.
@freezed
abstract class SyncedEvent with _$SyncedEvent {
  const factory SyncedEvent({
    @JsonKey(includeToJson: false) required String id,
    required String connectionId,
    @JsonKey(unknownEnumValue: CalendarProvider.ics)
    required CalendarProvider provider,

    /// Whose calendar it came from.
    required String memberId,

    /// The connection's account label: the host of a calendar link, which is
    /// what tells an iCloud calendar's badge to say Apple.
    @Default('') String sourceLabel,

    /// Empty when the provider had none; the row says "Busy" instead.
    @Default('') String title,
    @CalendarDateConverter() required CalendarDate date,

    /// The last day it covers, inclusive — a half-term holiday spans days.
    @CalendarDateConverter() required CalendarDate endDate,
    int? startMinute,
    int? endMinute,
  }) = _SyncedEvent;

  const SyncedEvent._();

  factory SyncedEvent.fromJson(Map<String, Object?> json) =>
      _$SyncedEventFromJson(json);

  bool get isAllDay => startMinute == null;

  /// Where it sorts in a day beside the household's own events.
  int get sortMinute => startMinute ?? -1;

  /// The days of [from]..[to] it appears on: every day of an all-day span,
  /// and only its first for a timed event that runs past midnight.
  List<CalendarDate> daysWithin(CalendarDate from, CalendarDate to) {
    final last = isAllDay ? endDate : date;
    final days = <CalendarDate>[];
    for (var day = date; !day.isAfter(last); day = day.addDays(1)) {
      if (day.isInRange(from, to)) days.add(day);
    }
    return days;
  }
}
