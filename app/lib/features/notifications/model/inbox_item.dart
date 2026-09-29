import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/time/calendar_date.dart';
import 'notification_vocabulary.dart';

part 'inbox_item.freezed.dart';
part 'inbox_item.g.dart';

/// One line of a digest section — "Swimming lesson", "15:00 · Leo".
@freezed
abstract class DigestLine with _$DigestLine {
  const factory DigestLine({required String text, String? detail}) =
      _DigestLine;

  factory DigestLine.fromJson(Map<String, Object?> json) =>
      _$DigestLineFromJson(json);
}

/// One section of a digest as the server composed it (notifications
/// ADR-0002): what kind, how many things it is about, and at most eight lines.
@freezed
abstract class DigestSection with _$DigestSection {
  const factory DigestSection({
    required String kind,
    @Default(0) int total,
    @Default(<DigestLine>[]) List<DigestLine> items,
  }) = _DigestSection;

  const DigestSection._();

  factory DigestSection.fromJson(Map<String, Object?> json) =>
      _$DigestSectionFromJson(json);

  DigestSectionKind? get sectionKind => DigestSectionKind.fromName(kind);
}

/// Where tapping lands (ADR-0001): a kind and an id, never a path.
@freezed
abstract class InboxTarget with _$InboxTarget {
  const factory InboxTarget({required String kind, String? id}) = _InboxTarget;

  const InboxTarget._();

  factory InboxTarget.fromJson(Map<String, Object?> json) =>
      _$InboxTargetFromJson(json);

  NotificationTarget get target => NotificationTarget.fromName(kind);
}

/// One notification for one person, at
/// `households/{id}/notificationInbox/{itemId}` (notifications ADR-0001).
/// Written only by Functions; its person reads it, marks it read and clears
/// it. The app never writes anything else on it.
@freezed
abstract class InboxItem with _$InboxItem {
  const factory InboxItem({
    @JsonKey(includeToJson: false) required String id,
    required String memberId,
    required String category,
    required String title,
    required String body,
    String? detail,
    @Default(<DigestSection>[]) List<DigestSection> sections,
    @Default(InboxTarget(kind: 'inboxItem')) InboxTarget target,
    @Default('') String localDate,
    @NullableTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? readAt,
  }) = _InboxItem;

  const InboxItem._();

  factory InboxItem.fromJson(Map<String, Object?> json) =>
      _$InboxItemFromJson(json);

  NotificationCategory get kind => NotificationCategory.fromName(category);

  bool get isUnread => readAt == null;

  /// The household day it is about, or null for one this build cannot read —
  /// shown then without its date, never a crash (`BE-10`).
  CalendarDate? get day {
    try {
      return CalendarDate.parse(localDate);
    } on FormatException {
      return null;
    }
  }
}
