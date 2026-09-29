import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/notifications/data/notification_repository.dart';
import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/notifications/model/notification_settings.dart';
import 'package:nestprep/features/notifications/model/push_arrival.dart';
import 'package:nestprep/features/notifications/state/inbox_controller.dart';
import 'package:nestprep/features/notifications/state/inbox_item_controller.dart';
import 'package:nestprep/features/notifications/state/notification_settings_controller.dart';
import 'package:nestprep/features/notifications/state/push_registrar.dart';
import 'package:nestprep/features/notifications/state/turn_on_notifications.dart';
import 'package:nestprep/features/notifications/ui/inbox_item_screen.dart';
import 'package:nestprep/features/notifications/ui/inbox_screen.dart';
import 'package:nestprep/features/notifications/ui/notification_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_notifications.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/notifications_fixtures.dart';
import 'review_press.dart';

/// Not a test — notifications for the screenshot press (notifications
/// ADR-0001 to ADR-0003): the inbox, a morning digest opened in full, the
/// settings, and the inbox on a phone that has not turned notifications on
/// yet, in light and dark. Regenerate with
///
///     flutter test tool/notifications_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final now = DateTime.now().toUtc();

  InboxItem richDigest() => InboxItem(
    id: 'digest_m-sam_today',
    memberId: Fixtures.samMemberId,
    category: 'digest',
    title: 'Your Tuesday at a glance',
    body:
        '3 events · 3 things to pack · 2 chores · 1 document to renew · '
        '1 shift update · 2 things to check',
    sections: const [
      DigestSection(
        kind: 'events',
        total: 3,
        items: [
          DigestLine(text: 'School run', detail: '07:15 · You, Kid Parker'),
          DigestLine(text: 'Swimming lesson', detail: '15:00 · Kid Parker'),
          DigestLine(text: 'Parents’ evening', detail: '18:30 · Everyone'),
        ],
      ),
      DigestSection(
        kind: 'pack',
        total: 3,
        items: [
          DigestLine(
            text: 'Kid Parker’s lunch box',
            detail: 'Cheese sandwich · Apple · Carrot sticks',
          ),
          DigestLine(
            text: 'Swimming kit',
            detail: 'Kid Parker · Swimming lesson at 15:00',
          ),
          DigestLine(text: 'Library books', detail: 'Kid Parker · Library day'),
        ],
      ),
      DigestSection(
        kind: 'chores',
        total: 2,
        items: [
          DigestLine(text: 'Bins out', detail: 'For you'),
          DigestLine(text: 'Make your bed', detail: 'For Kid Parker'),
        ],
      ),
      DigestSection(
        kind: 'documents',
        total: 1,
        items: [
          DigestLine(text: 'Car licence disc', detail: 'Expires in 12 days'),
        ],
      ),
      DigestSection(
        kind: 'shift',
        total: 1,
        items: [
          DigestLine(text: 'Handover from Nomsa', detail: '6 moments logged'),
        ],
      ),
      DigestSection(
        kind: 'approvals',
        total: 2,
        items: [
          DigestLine(
            text: '1 chore to check',
            detail: 'Stars wait for your look',
          ),
          DigestLine(
            text: '1 reward asked for',
            detail: 'Hand it over when it happens',
          ),
        ],
      ),
    ],
    target: const InboxTarget(kind: 'inboxItem', id: 'digest_m-sam_today'),
    localDate: '2026-09-29',
    createdAt: now.subtract(const Duration(hours: 2)),
  );

  List<InboxItem> inbox() => [
    richDigest(),
    InboxItem(
      id: 'chore_bed_1_m-sam',
      memberId: Fixtures.samMemberId,
      category: 'chores',
      title: 'A chore is waiting for your check',
      body: 'Have a look, and the stars land.',
      detail: 'Kid Parker · Make your bed',
      target: const InboxTarget(kind: 'stars'),
      localDate: '2026-09-29',
      createdAt: now.subtract(const Duration(minutes: 40)),
    ),
    NotificationFixtures.handover(
      createdAt: now.subtract(const Duration(days: 1)),
    ).copyWith(readAt: now),
    InboxItem(
      id: 'expiry_r1_m-sam',
      memberId: Fixtures.samMemberId,
      category: 'documents',
      title: 'A document needs renewing',
      body: 'One of the household’s documents expires in 30 days.',
      detail: 'Kid Parker passport · Expires in 30 days',
      target: const InboxTarget(kind: 'documents', id: 'passport'),
      localDate: '2026-09-26',
      createdAt: now.subtract(const Duration(days: 3)),
      readAt: now,
    ),
  ];

  Future<PushRegistrar> registrarWith(
    WidgetTester tester,
    PushPermission permission,
  ) async {
    final made = NotificationFixtures.registrar(
      gateway: FakePushGateway(current: permission),
    );
    addTearDown(() async {
      made.$1.dispose();
      made.$3.dispose();
      await made.$2.close();
    });
    await made.$1.start();
    return made.$1;
  }

  for (final brightness in Brightness.values) {
    testWidgets('inbox ${brightness.name}', (tester) async {
      final repository = FakeNotificationRepository(items: inbox());
      final registrar = await registrarWith(tester, PushPermission.granted);
      final controller = InboxController(
        repository: repository,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'notifications-inbox-${brightness.name}',
        screen: const InboxScreen(),
        providers: [
          Provider<NotificationRepository>.value(value: repository),
          ChangeNotifierProvider<PushRegistrar>.value(value: registrar),
          ChangeNotifierProvider<InboxController>.value(value: controller),
        ],
        brightness: brightness,
        emit: () async {},
      );
    });

    testWidgets('digest ${brightness.name}', (tester) async {
      final repository = FakeNotificationRepository(items: [richDigest()]);
      final controller = InboxItemController(
        repository: repository,
        householdId: Fixtures.householdId,
        itemId: 'digest_m-sam_today',
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'notifications-digest-${brightness.name}',
        screen: const InboxItemScreen(),
        providers: [
          ChangeNotifierProvider<InboxItemController>.value(value: controller),
        ],
        brightness: brightness,
        emit: () async {},
      );
    });

    testWidgets('settings ${brightness.name}', (tester) async {
      final repository = FakeNotificationRepository()
        ..setSettings(
          NotificationSettings.firstTime(
            memberId: Fixtures.samMemberId,
            updatedBy: Fixtures.samMemberId,
            isFamily: true,
          ),
        );
      final registrar = await registrarWith(tester, PushPermission.granted);
      final directory = FakeNotificationDirectory();
      final controller = NotificationSettingsController(
        repository: repository,
        directory: directory,
        registrar: registrar,
        owner: const NotificationsOwner(
          householdId: Fixtures.householdId,
          memberId: Fixtures.samMemberId,
          isFamily: true,
        ),
        kids: [Fixtures.kid],
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'notifications-settings-${brightness.name}',
        screen: const NotificationSettingsScreen(),
        providers: [
          ChangeNotifierProvider<PushRegistrar>.value(value: registrar),
          ChangeNotifierProvider<NotificationSettingsController>.value(
            value: controller,
          ),
        ],
        brightness: brightness,
        emit: () async {},
        act: () async {
          await tester.tap(find.text('Send me a test'));
          await tester.pumpAndSettle();
        },
      );
    });
  }

  testWidgets('first run light', (tester) async {
    final repository = FakeNotificationRepository();
    final registrar = await registrarWith(tester, PushPermission.notAsked);
    final controller = InboxController(
      repository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    addTearDown(controller.dispose);
    await captureScreen(
      tester,
      'notifications-first-run-light',
      screen: const InboxScreen(),
      providers: [
        Provider<NotificationRepository>.value(value: repository),
        ChangeNotifierProvider<PushRegistrar>.value(value: registrar),
        ChangeNotifierProvider<InboxController>.value(value: controller),
      ],
      emit: () async {},
    );
  });

  testWidgets('digest dark at 200% text', (tester) async {
    final repository = FakeNotificationRepository(items: [richDigest()]);
    final controller = InboxItemController(
      repository: repository,
      householdId: Fixtures.householdId,
      itemId: 'digest_m-sam_today',
    );
    addTearDown(controller.dispose);
    await captureScreen(
      tester,
      'notifications-digest-dark-200-percent-text',
      screen: const InboxItemScreen(),
      providers: [
        ChangeNotifierProvider<InboxItemController>.value(value: controller),
      ],
      brightness: Brightness.dark,
      textScale: 2,
      emit: () async {},
    );
  });
}
