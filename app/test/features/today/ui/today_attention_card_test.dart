import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/notifications_route.dart';
import 'package:nestprep/features/notifications/data/notification_repository.dart';
import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/today/ui/today_attention_card.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_notifications.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/notifications_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  late FakeNotificationRepository repository;

  setUp(() => repository = FakeNotificationRepository());
  tearDown(() => repository.close());

  InboxItem chore(String id) => InboxItem(
    id: id,
    memberId: Fixtures.samMemberId,
    category: 'chores',
    title: 'A chore is waiting for your check',
    body: 'Have a look, and the stars land.',
    target: const InboxTarget(kind: 'stars'),
  );

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpRouter(
      tester,
      brightness: brightness,
      textScale: textScale,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: [TodayAttentionCard()]),
              ),
            ),
          ),
          GoRoute(
            path: NotificationsRoute.pathFor(Fixtures.householdId),
            builder: (_, _) => const Text('the inbox'),
          ),
        ],
      ),
      providers: [Provider<NotificationRepository>.value(value: repository)],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('counts what waits, by kind, leaving out the digest', (
    tester,
  ) async {
    repository.setItems([
      NotificationFixtures.digest(),
      NotificationFixtures.handover(),
      chore('c1'),
      chore('c2'),
    ]);
    await pump(tester);

    expect(find.text('1 shift handover · 2 star requests'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        TodayCopy.attentionLabel(
          TodayCopy.attentionTitle(3),
          '1 shift handover · 2 star requests',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows nothing while nothing waits, and appears when it does', (
    tester,
  ) async {
    repository.setItems([NotificationFixtures.digest()]);
    await pump(tester);
    expect(find.textContaining('need'), findsNothing);

    repository.setItems([chore('c1')]);
    await tester.pumpAndSettle();
    expect(find.text('1 star request'), findsOneWidget);

    await repository.markRead(Fixtures.householdId, 'c1');
    await tester.pumpAndSettle();
    expect(find.text('1 star request'), findsNothing);
  });

  testWidgets('a tap opens the inbox', (tester) async {
    repository.setItems([chore('c1')]);
    await pump(tester);

    await tester.tap(find.text('1 star request'));
    await tester.pumpAndSettle();

    expect(find.text('the inbox'), findsOneWidget);
  });

  testWidgets('holds at phone width, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repository.setItems([
      NotificationFixtures.handover(),
      chore('c1'),
      const InboxItem(
        id: 'doc',
        memberId: Fixtures.samMemberId,
        category: 'documents',
        title: 'A document needs renewing',
        body: '',
      ),
      const InboxItem(
        id: 'home',
        memberId: Fixtures.samMemberId,
        category: 'coParenting',
        title: 'The other home asked to swap days',
        body: '',
      ),
    ]);
    await pump(tester, brightness: Brightness.dark, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
