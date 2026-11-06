import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/notifications/model/attention_summary.dart';
import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/notifications/model/notification_vocabulary.dart';

import '../../../support/household_fixtures.dart';

void main() {
  InboxItem item(String id, String category, {bool read = false}) => InboxItem(
    id: id,
    memberId: Fixtures.samMemberId,
    category: category,
    title: id,
    body: '',
    readAt: read ? DateTime.utc(2026) : null,
  );

  test('counts unread notifications by kind, in vocabulary order', () {
    final summary = AttentionSummary.of([
      item('a', 'places'),
      item('b', 'chores'),
      item('c', 'chores'),
      item('d', 'documents'),
    ]);

    expect(summary.total, 4);
    expect(summary.byKind.keys, [
      NotificationCategory.documents,
      NotificationCategory.chores,
      NotificationCategory.places,
    ]);
    expect(summary.byKind[NotificationCategory.chores], 2);
  });

  test('leaves out what is read, the digest and the test push', () {
    final summary = AttentionSummary.of([
      item('a', 'chores', read: true),
      item('b', 'digest'),
      item('c', 'test'),
    ]);

    expect(summary.isEmpty, isTrue);
    expect(summary.total, 0);
  });

  test('a kind a newer server wrote still counts', () {
    final summary = AttentionSummary.of([item('a', 'somethingNew')]);

    expect(summary.total, 1);
  });
}
