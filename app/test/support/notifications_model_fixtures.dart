import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/notifications/model/notification_settings.dart';
import 'package:nestprep/features/notifications/model/push_token.dart';

import 'model_fixtures.dart';

/// Notifications' stored models (notifications ADR-0001, ADR-0003), every
/// field populated, in a file of their own that `modelFixtures()` spreads.
List<ModelFixture> notificationsModelFixtures() {
  final at = fixtureInstant;

  const settings = NotificationSettings(
    id: 'm-sam',
    digest: DigestChoice(enabled: true, minute: 420),
    categories: {'documents': true, 'handover': false, 'chores': true},
    quietHours: QuietHours(enabled: false, startMinute: 1320, endMinute: 420),
    updatedBy: 'm-sam',
  );
  final item = InboxItem(
    id: 'digest_m-sam_2026-09-29',
    memberId: 'm-sam',
    category: 'digest',
    title: 'Your Tuesday at a glance',
    body: '3 events · 1 chore',
    detail: 'From Nomsa · 6 moments',
    sections: const [
      DigestSection(
        kind: 'events',
        total: 3,
        items: [DigestLine(text: 'Swimming lesson', detail: '15:00 · Leo')],
      ),
    ],
    target: const InboxTarget(kind: 'inboxItem', id: 'digest_m-sam_2026-09-29'),
    localDate: '2026-09-29',
    createdAt: at,
    readAt: at,
  );
  final token = PushToken(
    id: 'token-sam',
    token: 'token-sam',
    platform: PushPlatform.android,
    updatedAt: at,
  );

  return [
    ModelFixture(
      label: 'NotificationSettings',
      id: settings.id,
      keys: const {
        'digest',
        'categories',
        'quietHours',
        'updatedBy',
        'updatedAt',
      },
      value: settings.copyWith(updatedAt: at),
      toJson: () => settings.copyWith(updatedAt: at).toJson(),
      fromJson: NotificationSettings.fromJson,
      note:
          '`digestSlot` is written beside these by the repository, derived '
          'from `digest` — never chosen, and held to it by the rules '
          '(notifications ADR-0002).',
    ),
    ModelFixture(
      label: 'InboxItem',
      id: item.id,
      keys: const {
        'memberId',
        'category',
        'title',
        'body',
        'detail',
        'sections',
        'target',
        'localDate',
        'createdAt',
        'readAt',
      },
      value: item,
      toJson: item.toJson,
      fromJson: InboxItem.fromJson,
      note:
          'written only by Functions; the app reads it and stamps `readAt` '
          '(notifications ADR-0001).',
    ),
    ModelFixture(
      label: 'PushToken',
      id: token.id,
      keys: const {'token', 'platform', 'updatedAt'},
      value: token,
      toJson: token.toJson,
      fromJson: PushToken.fromJson,
    ),
  ];
}
