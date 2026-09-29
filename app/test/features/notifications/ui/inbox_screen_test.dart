import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/features/notifications/data/notification_repository.dart';
import 'package:nestprep/features/notifications/model/push_arrival.dart';
import 'package:nestprep/features/notifications/state/inbox_controller.dart';
import 'package:nestprep/features/notifications/state/push_registrar.dart';
import 'package:nestprep/features/notifications/ui/inbox_screen.dart';
import 'package:nestprep/shared/copy/notifications_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_notifications.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/notifications_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The inbox (notifications ADR-0001) in all four states, with the card that
/// turns notifications on above it — never in place of it — and each row
/// going where it belongs.
void main() {
  late FakeNotificationRepository repository;
  late InboxController controller;
  late PushRegistrar registrar;
  late FakePushGateway gateway;
  late String? landedOn;

  setUp(() {
    repository = FakeNotificationRepository();
    final made = NotificationFixtures.registrar();
    registrar = made.$1;
    gateway = made.$2;
    landedOn = null;
  });

  tearDown(() async {
    controller.dispose();
    registrar.dispose();
    await gateway.close();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) {
    // Made inside the test, so its listener lives in the test's clock.
    controller = InboxController(
      repository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    return pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: '/inbox',
        routes: [
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxScreen(),
          ),
          GoRoute(
            path: '/households/:householdId/notifications/:rest',
            builder: (context, state) {
              landedOn = state.uri.path;
              return const Placeholder();
            },
          ),
          GoRoute(
            path: '/households/:householdId/nanny/summaries/:shiftId',
            builder: (context, state) {
              landedOn = state.uri.path;
              return const Placeholder();
            },
          ),
        ],
      ),
      providers: [
        Provider<NotificationRepository>.value(value: repository),
        ChangeNotifierProvider<PushRegistrar>.value(value: registrar),
        ChangeNotifierProvider<InboxController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
  }

  testWidgets('holds the layout while it loads', (tester) async {
    repository.isLoading = true;
    await pump(tester);
    expect(find.text(NotificationsCopy.inboxTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('loading')), findsOneWidget);
  });

  testWidgets('empty says what lands here, and the way in stays above it', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(NotificationsCopy.emptyTitle), findsOneWidget);
    expect(find.text(NotificationsCopy.turnOn), findsOneWidget);
  });

  testWidgets('turning on asks the phone once, and the card goes', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text(NotificationsCopy.turnOn));
    await tester.pumpAndSettle();
    expect(gateway.prompts, 1);
    expect(find.text(NotificationsCopy.turnOn), findsNothing);
    // The first yes writes the person's choices with the defaults (ADR-0003).
    expect(repository.settingsOf(Fixtures.samMemberId)?.digest.enabled, isTrue);
  });

  testWidgets('a phone that said no is told where the switch is', (
    tester,
  ) async {
    gateway.current = PushPermission.denied;
    await registrar.start();
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(NotificationsCopy.deniedMessage), findsOneWidget);
    expect(find.text(NotificationsCopy.turnOn), findsNothing);
  });

  testWidgets('a read that fails is words and a retry, never the error', (
    tester,
  ) async {
    repository.failInboxWith(const UnavailableFailure());
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('error')), findsOneWidget);
  });

  testWidgets('today apart from before, the unread marked in words', (
    tester,
  ) async {
    repository.setItems([
      NotificationFixtures.digest(),
      NotificationFixtures.handover(),
    ]);
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(NotificationsCopy.today), findsOneWidget);
    expect(find.text(NotificationsCopy.earlier), findsOneWidget);
    expect(find.text('Your Tuesday at a glance'), findsOneWidget);
    expect(find.text('From Nomsa · 6 moments'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(NotificationsCopy.unread)),
      findsWidgets,
    );
  });

  testWidgets('a digest opens in full', (tester) async {
    repository.setItems([NotificationFixtures.digest()]);
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your Tuesday at a glance'));
    await tester.pumpAndSettle();
    expect(landedOn, '/households/h1/notifications/digest_m-sam_2026-09-29');
  });

  testWidgets('a handover opens the handover, read by being tapped', (
    tester,
  ) async {
    repository.setItems([NotificationFixtures.handover()]);
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('The shift handover is ready'));
    await tester.pumpAndSettle();
    expect(landedOn, '/households/h1/nanny/summaries/shift-1');
    expect(repository.markedRead, ['handover_shift-1_m-sam']);
  });

  testWidgets('mark all read, and a swipe clears one', (tester) async {
    repository.setItems([NotificationFixtures.digest()]);
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(NotificationsCopy.markAllRead));
    await tester.pumpAndSettle();
    expect(repository.markedRead, ['digest_m-sam_2026-09-29']);

    await tester.drag(
      find.text('Your Tuesday at a glance'),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(repository.cleared, ['digest_m-sam_2026-09-29']);
    expect(find.text(NotificationsCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repository.setItems([
      NotificationFixtures.digest(),
      NotificationFixtures.handover(),
    ]);
    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
