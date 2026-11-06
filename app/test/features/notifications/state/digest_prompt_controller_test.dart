import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/notifications/model/notification_vocabulary.dart';
import 'package:nestprep/features/notifications/state/digest_prompt_controller.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_notifications.dart';

/// Today's digest offered on the first open of the household's day on this
/// device (notifications ADR-0005): once, only while it is unread, and a day
/// with nothing to offer is not used up.
void main() {
  const householdId = 'h1';
  const memberId = 'm-sam';
  final monday = CalendarDate(2026, 11, 2);
  final tuesday = CalendarDate(2026, 11, 3);

  InboxItem digestOn(CalendarDate day, {bool read = false}) => InboxItem(
    id: DigestIds.of(memberId, day),
    memberId: memberId,
    category: 'digest',
    title: 'Your day at a glance',
    body: '1 event',
    localDate: day.iso,
    readAt: read ? DateTime.utc(2026) : null,
  );

  late FakeNotificationRepository repository;
  late FakeDigestPromptStore store;
  late DateTime now;
  late DigestPromptController controller;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    repository = FakeNotificationRepository();
    store = FakeDigestPromptStore();
    now = DateTime.utc(2026, 11, 2, 5);
    controller = DigestPromptController(
      repository: repository,
      store: store,
      clock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: householdId,
      memberId: memberId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('offers an unread digest for today and remembers the day', () async {
    repository.setItems([digestOn(monday)]);
    await controller.opened();
    await settle();

    expect(controller.digest?.id, DigestIds.of(memberId, monday));
    expect(store.offered['$householdId/$memberId'], monday);
  });

  test('a later open on the same day offers nothing', () async {
    repository.setItems([digestOn(monday)]);
    await store.markOffered(householdId, memberId, monday);
    await controller.opened();
    await settle();

    expect(controller.digest, isNull);
  });

  test('a digest already read is not offered', () async {
    repository.setItems([digestOn(monday, read: true)]);
    await controller.opened();
    await settle();

    expect(controller.digest, isNull);
    expect(store.offered, isEmpty);
  });

  test('a day with no digest yet is not used up', () async {
    await controller.opened();
    await settle();
    expect(controller.digest, isNull);
    expect(store.offered, isEmpty);

    repository.setItems([digestOn(monday)]);
    expect(controller.digest, isNull, reason: 'only an open offers it');

    await controller.opened();
    await settle();
    expect(controller.digest?.id, DigestIds.of(memberId, monday));
  });

  test('goes away once the digest is read somewhere else', () async {
    repository.setItems([digestOn(monday)]);
    await controller.opened();
    await settle();

    await repository.markRead(householdId, DigestIds.of(memberId, monday));
    expect(controller.digest, isNull);
  });

  test('stays through a same-day return and is dismissed by hand', () async {
    repository.setItems([digestOn(monday)]);
    await controller.opened();
    await settle();

    await controller.opened();
    await settle();
    expect(controller.digest, isNotNull);

    controller.dismiss();
    expect(controller.digest, isNull);
  });

  test('an app kept in memory overnight swaps in the new day', () async {
    repository.setItems([digestOn(monday), digestOn(tuesday)]);
    await controller.opened();
    await settle();
    expect(controller.digest?.id, DigestIds.of(memberId, monday));

    now = DateTime.utc(2026, 11, 3, 5);
    await controller.opened();
    await settle();

    expect(controller.digest?.id, DigestIds.of(memberId, tuesday));
    expect(store.offered['$householdId/$memberId'], tuesday);
  });

  test('a profile not yet claimed is offered nothing', () async {
    final unclaimed = DigestPromptController(
      repository: repository,
      store: store,
      clock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: householdId,
      memberId: '',
    );
    addTearDown(unclaimed.dispose);
    repository.setItems([digestOn(monday)]);

    await unclaimed.opened();
    await settle();

    expect(unclaimed.digest, isNull);
  });
}
