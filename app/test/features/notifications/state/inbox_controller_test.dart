import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/notifications/state/inbox_controller.dart';
import 'package:nestprep/features/notifications/state/inbox_item_controller.dart';
import 'package:nestprep/features/notifications/state/unread_count_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_notifications.dart';

/// A person's inbox (notifications ADR-0001): only their own, read and cleared
/// by them; an opened notification marks itself read once; the bell counts
/// what is unread and falls quiet rather than wrong when it cannot.
void main() {
  InboxItem item(String id, {String memberId = 'm-sam', bool read = false}) =>
      InboxItem(
        id: id,
        memberId: memberId,
        category: 'digest',
        title: 'Your Tuesday at a glance',
        body: '1 event',
        readAt: read ? DateTime.utc(2026) : null,
      );

  late FakeNotificationRepository repository;

  setUp(() {
    repository = FakeNotificationRepository(
      items: [
        item('a'),
        item('b', read: true),
        item('pat', memberId: 'm-pat'),
      ],
    );
  });

  tearDown(() => repository.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('lists only the person’s own, and marks all read in one tap', () async {
    final controller = InboxController(
      repository: repository,
      householdId: 'h1',
      memberId: 'm-sam',
    );
    addTearDown(controller.dispose);
    await settle();
    final items = (controller.items as AsyncData<List<InboxItem>>).value;
    expect(items.map((each) => each.id), ['a', 'b']);
    expect(controller.hasUnread, isTrue);
    await controller.markAllRead();
    await settle();
    expect(repository.markedRead, ['a']);
    expect(controller.hasUnread, isFalse);
  });

  test('clears one, and holds a refusal for the screen', () async {
    final controller = InboxController(
      repository: repository,
      householdId: 'h1',
      memberId: 'm-sam',
    );
    addTearDown(controller.dispose);
    await settle();
    await controller.clear(item('a'));
    expect(repository.cleared, ['a']);
    repository.failWritesWith = const UnavailableFailure();
    await controller.clear(item('b'));
    expect(controller.actionFailure, isA<UnavailableFailure>());
  });

  test('a read that fails is the error state, with its retry', () async {
    repository.failInboxWith(const PermissionDeniedFailure());
    final controller = InboxController(
      repository: repository,
      householdId: 'h1',
      memberId: 'm-sam',
    );
    addTearDown(controller.dispose);
    await settle();
    expect(controller.items, isA<AsyncFailure<List<InboxItem>>>());
  });

  test('opening an unread notification marks it read, once', () async {
    final controller = InboxItemController(
      repository: repository,
      householdId: 'h1',
      itemId: 'a',
    );
    addTearDown(controller.dispose);
    await settle();
    await settle();
    expect(repository.markedRead, ['a']);
    expect((controller.item as AsyncData<InboxItem?>).value?.isUnread, isFalse);
  });

  test('a cleared notification is nothing, not an error', () async {
    final controller = InboxItemController(
      repository: repository,
      householdId: 'h1',
      itemId: 'gone',
    );
    addTearDown(controller.dispose);
    await settle();
    expect(controller.item, isA<AsyncData<InboxItem?>>());
    expect((controller.item as AsyncData<InboxItem?>).value, isNull);
  });

  test(
    'the bell counts what is unread, and is quiet when it cannot read',
    () async {
      final counter = UnreadCountController(
        repository: repository,
        householdId: 'h1',
        memberId: 'm-sam',
      );
      addTearDown(counter.dispose);
      await settle();
      expect(counter.count, 1);
      repository.failInboxWith(const UnavailableFailure());
      await settle();
      expect(counter.count, 0);
    },
  );
}
