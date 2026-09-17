import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';

part 'event_exception.freezed.dart';
part 'event_exception.g.dart';

/// One occurrence of a repeating event, skipped. Stored flat under the
/// household at `households/{id}/eventExceptions/{eventId}_{date}`, for the same
/// reason completions are (todos ADR-0002).
///
/// In v1 an occurrence can be skipped, not moved (calendar ADR-0001).
@freezed
abstract class EventException with _$EventException {
  const factory EventException({
    @JsonKey(includeToJson: false) required String id,
    required String eventId,
    @CalendarDateConverter() required CalendarDate occurrenceDate,
    required String skippedBy,
    @ServerTimestampConverter() DateTime? skippedAt,
  }) = _EventException;

  const EventException._();

  factory EventException.fromJson(Map<String, Object?> json) =>
      _$EventExceptionFromJson(json);

  /// Derived, so skipping the same occurrence twice is the same write
  /// (`BE-06`).
  static String idFor(String eventId, CalendarDate date) =>
      '${eventId}_${date.iso}';
}
