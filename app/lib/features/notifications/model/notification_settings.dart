import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'notification_vocabulary.dart';

part 'notification_settings.freezed.dart';
part 'notification_settings.g.dart';

/// The digest's switch and its time — a quarter hour on the household's clock
/// (notifications ADR-0002).
@freezed
abstract class DigestChoice with _$DigestChoice {
  const factory DigestChoice({
    @Default(false) bool enabled,
    @Default(DigestTimes.defaultMinute) int minute,
  }) = _DigestChoice;

  factory DigestChoice.fromJson(Map<String, Object?> json) =>
      _$DigestChoiceFromJson(json);
}

/// When pushes wait for the morning. The inbox has a notification at once;
/// only the buzz waits (ADR-0001).
@freezed
abstract class QuietHours with _$QuietHours {
  const factory QuietHours({
    @Default(true) bool enabled,
    @Default(DigestTimes.quietStart) int startMinute,
    @Default(DigestTimes.quietEnd) int endMinute,
  }) = _QuietHours;

  factory QuietHours.fromJson(Map<String, Object?> json) =>
      _$QuietHoursFromJson(json);
}

/// One person's notification choices, at
/// `households/{id}/notificationSettings/{memberId}` (notifications
/// ADR-0003). A person writes their own; family may also write a kid's. The
/// digest job reads `digestSlot`, which the repository writes from [digest]
/// and the rules hold to it.
@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    /// The member these are for — the document id.
    @JsonKey(includeToJson: false) required String id,
    @Default(DigestChoice()) DigestChoice digest,
    @Default(<String, bool>{}) Map<String, bool> categories,
    @Default(QuietHours()) QuietHours quietHours,
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _NotificationSettings;

  const NotificationSettings._();

  factory NotificationSettings.fromJson(Map<String, Object?> json) =>
      _$NotificationSettingsFromJson(json);

  /// What a person gets the first time they turn notifications on: the
  /// digest at 06:30 for family, off for a kid, helper or carer, who choose it
  /// themselves; every reminder; quiet nights (ADR-0003).
  factory NotificationSettings.firstTime({
    required String memberId,
    required String updatedBy,
    required bool isFamily,
  }) => NotificationSettings(
    id: memberId,
    digest: DigestChoice(enabled: isFamily),
    categories: {
      for (final category in SwitchableCategory.values) category.name: true,
    },
    updatedBy: updatedBy,
  );

  /// Nothing stored yet: exactly what the server assumes (ADR-0003).
  factory NotificationSettings.unchosen(String memberId) =>
      NotificationSettings(id: memberId, updatedBy: memberId);

  /// The quarter hour the digest job asks for, or null while it is off.
  int? get digestSlot =>
      digest.enabled ? digest.minute ~/ DigestTimes.stepMinutes : null;

  bool wants(SwitchableCategory category) => categories[category.name] ?? true;

  NotificationSettings withCategory(SwitchableCategory category, bool on) =>
      copyWith(
        categories: {
          for (final each in SwitchableCategory.values)
            each.name: each == category ? on : wants(each),
        },
      );
}
