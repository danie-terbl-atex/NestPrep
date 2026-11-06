import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/features/notifications/data/digest_prompt_store.dart';
import 'package:nestprep/features/notifications/data/notification_repository.dart';
import 'package:nestprep/features/notifications/model/notification_vocabulary.dart';
import 'package:nestprep/features/notifications/ui/digest_prompt_host.dart';
import 'package:nestprep/shared/copy/notifications_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_notifications.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/notifications_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The banner on top of the household (notifications ADR-0005): it slides in
/// on the first open, lands on the digest the push would open, lets go when
/// closed, and fits in dark at 200% text on a small phone.
void main() {
  final today = CalendarDate(2026, 9, 29);
  final digestId = DigestIds.of(Fixtures.samMemberId, today);
  final digestPath =
      '/households/${Fixtures.householdId}/notifications/$digestId';

  late FakeNotificationRepository repository;
  late FakeDigestPromptStore store;
  late String? landedOn;

  setUp(() {
    repository = FakeNotificationRepository(
      items: [NotificationFixtures.digest(id: digestId)],
    );
    store = FakeDigestPromptStore();
    landedOn = null;
  });

  tearDown(() => repository.close());

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
        initialLocation: '/households/${Fixtures.householdId}/today',
        routes: [
          ShellRoute(
            builder: (context, state, child) => DigestPromptHost(
              householdId: Fixtures.householdId,
              memberId: Fixtures.samMemberId,
              location: state.uri.path,
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/households/:householdId/today',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('today'))),
              ),
              GoRoute(
                path: '/households/:householdId/notifications/:itemId',
                builder: (context, state) {
                  landedOn = state.uri.path;
                  return const Scaffold(body: Text('the digest'));
                },
              ),
            ],
          ),
        ],
      ),
      providers: [
        Provider<NotificationRepository>.value(value: repository),
        Provider<DigestPromptStore>.value(value: store),
        Provider<HouseholdClock>.value(
          value: HouseholdClock(
            'Africa/Johannesburg',
            now: () => DateTime.utc(2026, 9, 29, 5),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  final digest = NotificationFixtures.digest();

  testWidgets('slides in with today’s digest and opens it', (tester) async {
    await pump(tester);

    expect(
      find.text(NotificationsCopy.digestPromptEyebrow.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(digest.title), findsOneWidget);
    expect(store.offered.values.single, today);

    await tester.tap(find.text(digest.title));
    await tester.pumpAndSettle();

    expect(landedOn, digestPath);
    expect(find.text(digest.title), findsNothing);
  });

  testWidgets('closing it lets it go for the day', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip(NotificationsCopy.digestPromptDismiss));
    await tester.pumpAndSettle();

    expect(find.text(digest.title), findsNothing);
    expect(landedOn, isNull);
  });

  testWidgets('a later open the same day shows nothing', (tester) async {
    await store.markOffered(Fixtures.householdId, Fixtures.samMemberId, today);
    await pump(tester);

    expect(find.text(digest.title), findsNothing);
  });

  testWidgets('fits in dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, textScale: 2);

    expect(find.text(digest.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
