import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_connection.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_feed_link.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/model/connection_status.dart';
import 'package:nestprep/features/calendar_sync/state/connected_calendars_controller.dart';
import 'package:nestprep/features/calendar_sync/ui/connected_calendars_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/calendar_sync_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_calendar_sync.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The connected calendars screen (calendar ADR-0003) in all four states, the
/// ways in that must survive every one of them, and every action a member can
/// reach from it.
final _now = DateTime.utc(2026, 9, 29, 10);

CalendarConnection _google({
  String ownerUid = Fixtures.thandiUid,
  ConnectionStatus status = ConnectionStatus.connected,
}) => CalendarConnection(
  id: 'c1',
  provider: CalendarProvider.google,
  memberId: Fixtures.thandiMemberId,
  ownerUid: ownerUid,
  accountLabel: 'thandi@example.com',
  status: status,
  eventCount: 3,
  lastSyncedAt: _now.subtract(const Duration(minutes: 12)),
);

void main() {
  late FakeCalendarSyncRepository repository;
  late FakeCalendarSyncDirectory directory;
  late FakeLinkOpener opener;

  setUp(() {
    repository = FakeCalendarSyncRepository();
    directory = FakeCalendarSyncDirectory();
    opener = FakeLinkOpener();
  });

  tearDown(() => repository.close());

  Future<ConnectedCalendarsController> pump(
    WidgetTester tester, {
    String viewerUid = Fixtures.thandiUid,
    bool isAdmin = false,
    bool canConnect = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final controller = ConnectedCalendarsController(
      calendarSyncRepository: repository,
      calendarSyncDirectory: directory,
      linkOpener: opener,
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
      isAdmin: isAdmin,
      canConnect: canConnect,
      now: () => _now,
    );
    await pumpScreen(
      tester,
      const ConnectedCalendarsScreen(),
      providers: [
        ChangeNotifierProvider<ConnectedCalendarsController>.value(
          value: controller,
        ),
      ],
      view: Fixtures.view(viewerUid: viewerUid),
      brightness: brightness,
      textScale: textScale,
    );
    addTearDown(controller.dispose);
    await tester.pump();
    return controller;
  }

  /// Settled with nothing connected: the loading skeleton pulses for as long
  /// as it shows, so a test that wants to settle gives it an answer first.
  Future<ConnectedCalendarsController> pumpSettled(
    WidgetTester tester, {
    String viewerUid = Fixtures.thandiUid,
    bool isAdmin = false,
  }) async {
    final controller = await pump(
      tester,
      viewerUid: viewerUid,
      isAdmin: isAdmin,
    );
    repository.emitConnections([]);
    await tester.pumpAndSettle();
    return controller;
  }

  /// Taps the [index]th (default: last) widget saying [text], scrolling the
  /// screen's list to it first when the list has not built it yet — the feed
  /// card sits below the fold (lesson: a tap below the fold lands elsewhere).
  Future<void> tapText(WidgetTester tester, String text, {int? index}) async {
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    final target = index == null
        ? find.text(text).last
        : find.text(text).at(index);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('the four states', () {
    testWidgets('while loading, the ways to connect are already there', (
      tester,
    ) async {
      await pump(tester);
      expect(
        find.text(CalendarSyncCopy.providerName(CalendarProvider.google)),
        findsOneWidget,
      );
      expect(find.text(CalendarSyncCopy.emptyTitle), findsNothing);
    });

    testWidgets('nothing connected says what to do, under the ways to do it', (
      tester,
    ) async {
      await pump(tester);
      repository.emitConnections([]);
      await tester.pumpAndSettle();
      expect(find.text(CalendarSyncCopy.emptyTitle), findsOneWidget);
      expect(find.text(CalendarSyncCopy.connect), findsWidgets);
    });

    testWidgets('a failed read is words and a retry, never the error', (
      tester,
    ) async {
      await pump(tester);
      repository.failConnectionsWith(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const UnavailableFailure())),
        findsOneWidget,
      );
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('a connection says whose it is and how its last sync went', (
      tester,
    ) async {
      await pump(tester);
      repository.emitConnections([_google()]);
      await tester.pumpAndSettle();
      expect(
        find.text(
          CalendarSyncCopy.connectionTitle(
            'Thandi Helper',
            CalendarProvider.google,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Synced 12 minutes ago'), findsOneWidget);
      expect(find.textContaining('3 events'), findsOneWidget);
    });

    testWidgets('a revoked connection says so in words', (tester) async {
      await pump(tester);
      repository.emitConnections([_google(status: ConnectionStatus.revoked)]);
      await tester.pumpAndSettle();
      expect(
        find.text(
          CalendarSyncCopy.status(
            ConnectionStatus.revoked,
            syncedAgo: null,
            eventCount: 0,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('revoked'), findsNothing);
    });
  });

  group('connecting', () {
    testWidgets(
      'a provider that is not set up says so where its button would be',
      (tester) async {
        await pumpSettled(tester);
        expect(find.text(CalendarSyncCopy.notSetUp), findsOneWidget);
        expect(find.text(CalendarSyncCopy.connect), findsNWidgets(2));
      },
    );

    testWidgets(
      'Google opens in the browser, and the screen says where to finish',
      (tester) async {
        await pump(tester);
        repository.emitConnections([]);
        await tester.pumpAndSettle();
        await tapText(tester, CalendarSyncCopy.connect, index: 0);
        expect(directory.started, [CalendarProvider.google]);
        expect(opener.opened, hasLength(1));
        expect(find.text(CalendarSyncCopy.browserOpened), findsOneWidget);
      },
    );

    testWidgets('a calendar link is pasted into a sheet and sent', (
      tester,
    ) async {
      await pumpSettled(tester);
      await tester.tap(find.text(CalendarSyncCopy.connect).last);
      await tester.pumpAndSettle();
      expect(find.text(CalendarSyncCopy.linkSheetTitle), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).last,
        'webcal://p01-caldav.icloud.com/published/2/x',
      );
      await tester.pump();
      await tapText(tester, CalendarSyncCopy.linkAdd);
      expect(directory.linked, [
        'webcal://p01-caldav.icloud.com/published/2/x',
      ]);
    });

    testWidgets('a link that is not a calendar is refused in words', (
      tester,
    ) async {
      directory.failWith = const CalendarSyncFailure(
        CalendarSyncProblem.notACalendarLink,
      );
      final controller = await pumpSettled(tester);
      await controller.connectLink('https://example.com');
      await tester.pumpAndSettle();
      expect(
        find.text(
          CalendarSyncCopy.problem(CalendarSyncProblem.notACalendarLink),
        ),
        findsOneWidget,
      );
    });
  });

  group('managing', () {
    testWidgets('the owner syncs now and disconnects, after saying yes', (
      tester,
    ) async {
      await pump(tester);
      repository.emitConnections([_google()]);
      await tester.pumpAndSettle();
      await tapText(tester, CalendarSyncCopy.syncNow);
      expect(directory.synced, ['c1']);

      await tapText(tester, CalendarSyncCopy.disconnect);
      expect(find.text(CalendarSyncCopy.disconnectConfirm), findsOneWidget);
      await tapText(tester, CalendarSyncCopy.disconnect);
      expect(directory.disconnected, ['c1']);
    });

    testWidgets('somebody else’s calendar can be seen but not managed', (
      tester,
    ) async {
      await pump(tester, viewerUid: Fixtures.samUid);
      repository.emitConnections([_google()]);
      await tester.pumpAndSettle();
      expect(find.text(CalendarSyncCopy.syncNow), findsNothing);
      expect(find.text(CalendarSyncCopy.disconnect), findsNothing);
    });
  });

  group('somebody the household lets only look at the week', () {
    // `view` on the calendar (household ADR-0003): what is connected and the
    // feed link, and no way to bring a calendar in or change one.
    testWidgets('sees no way to connect, and cannot manage even their own', (
      tester,
    ) async {
      await pump(tester, canConnect: false);
      repository.emitConnections([_google()]);
      await tester.pumpAndSettle();
      expect(find.text(CalendarSyncCopy.sectionConnect), findsNothing);
      expect(find.text(CalendarSyncCopy.syncNow), findsNothing);
      expect(find.text(CalendarSyncCopy.sectionShare), findsOneWidget);
    });
  });

  group('the feed', () {
    testWidgets('is made on request, then offered to subscribe to and copy', (
      tester,
    ) async {
      await pumpSettled(tester);
      await tapText(tester, CalendarSyncCopy.feedGetLink);
      expect(directory.feedsShared, 1);

      repository.emitFeed(
        const CalendarFeedLink('https://feed.test/calendarFeed?token=abc'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('https://feed.test/calendarFeed?token=abc'),
        findsOneWidget,
      );

      await tapText(tester, CalendarSyncCopy.feedSubscribe);
      expect(opener.opened.single.scheme, 'webcal');

      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      await tapText(tester, CalendarSyncCopy.feedCopy);
      expect(copied, ['https://feed.test/calendarFeed?token=abc']);
      expect(find.text(CalendarSyncCopy.feedCopied), findsOneWidget);
      expect(
        find.text(CalendarSyncCopy.feedReset),
        findsNothing,
        reason: 'not an admin',
      );
    });

    testWidgets('an admin can make a new link, after saying yes', (
      tester,
    ) async {
      await pumpSettled(tester, viewerUid: Fixtures.samUid, isAdmin: true);
      repository.emitFeed(const CalendarFeedLink('https://feed.test/x'));
      await tester.pumpAndSettle();
      await tapText(tester, CalendarSyncCopy.feedReset);
      expect(find.text(CalendarSyncCopy.feedResetConfirm), findsOneWidget);
      await tapText(tester, CalendarSyncCopy.feedReset);
      expect(directory.feedsReset, 1);
    });
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      viewerUid: Fixtures.samUid,
      isAdmin: true,
      brightness: Brightness.dark,
      textScale: 2,
    );
    repository
      ..emitConnections([
        _google(),
        _google(status: ConnectionStatus.unreachable),
      ])
      ..emitFeed(
        const CalendarFeedLink('https://feed.test/calendarFeed?token=abc'),
      );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
