import 'package:flutter/foundation.dart';
import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/notifications/state/push_registrar.dart';

import 'fake_notifications.dart';
import 'household_fixtures.dart';

/// Inbox items as the Functions write them (notifications ADR-0001), for the
/// screens' tests.
abstract final class NotificationFixtures {
  static InboxItem digest({
    String id = 'digest_m-sam_2026-09-29',
    DateTime? createdAt,
    bool read = false,
  }) => InboxItem(
    id: id,
    memberId: Fixtures.samMemberId,
    category: 'digest',
    title: 'Your Tuesday at a glance',
    body: '1 event · 2 things to pack · 1 chore',
    sections: const [
      DigestSection(
        kind: 'events',
        total: 1,
        items: [
          DigestLine(text: 'Swimming lesson', detail: '15:00 · Kid Parker'),
        ],
      ),
      DigestSection(
        kind: 'pack',
        total: 2,
        items: [
          DigestLine(
            text: 'Kid Parker’s lunch box',
            detail: 'Cheese sandwich · Apple',
          ),
          DigestLine(
            text: 'Swimming kit',
            detail: 'Kid Parker · Swimming lesson at 15:00',
          ),
        ],
      ),
      DigestSection(
        kind: 'chores',
        total: 1,
        items: [DigestLine(text: 'Bins out', detail: 'For you')],
      ),
    ],
    target: InboxTarget(kind: 'inboxItem', id: id),
    localDate: '2026-09-29',
    createdAt: createdAt ?? DateTime.now().toUtc(),
    readAt: read ? DateTime.now().toUtc() : null,
  );

  static InboxItem handover({DateTime? createdAt}) => InboxItem(
    id: 'handover_shift-1_m-sam',
    memberId: Fixtures.samMemberId,
    category: 'handover',
    title: 'The shift handover is ready',
    body: 'See how the shift went — every moment the carer logged.',
    detail: 'From Nomsa · 6 moments',
    target: const InboxTarget(kind: 'shiftSummary', id: 'shift-1'),
    localDate: '2026-09-28',
    createdAt:
        createdAt ?? DateTime.now().toUtc().subtract(const Duration(days: 2)),
  );

  /// A registrar over a fake phone, following a session the test holds.
  static (PushRegistrar, FakePushGateway, ValueNotifier<String>) registrar({
    FakePushGateway? gateway,
  }) {
    final phone = gateway ?? FakePushGateway();
    final session = ValueNotifier(Fixtures.samUid);
    final registrar = PushRegistrar(
      gateway: phone,
      tokens: FakePushTokenRepository(),
      session: session,
      signedInUid: () => session.value,
    );
    return (registrar, phone, session);
  }
}
