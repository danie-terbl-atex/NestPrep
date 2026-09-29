import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_connection.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_feed_link.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/model/connection_status.dart';
import 'package:nestprep/features/calendar_sync/model/provider_availability.dart';
import 'package:nestprep/features/calendar_sync/state/connected_calendars_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_calendar_sync.dart';
import '../../../support/household_fixtures.dart';

/// The connected calendars controller (calendar ADR-0003): it shows what the
/// listeners hold, asks the Functions to act, and keeps every refusal for the
/// screen to put into words.
final _now = DateTime.utc(2026, 9, 29, 10);

CalendarConnection connection({
  String id = 'c1',
  CalendarProvider provider = CalendarProvider.google,
  String ownerUid = Fixtures.thandiUid,
  String label = 'thandi@example.com',
  DateTime? lastSyncedAt,
}) => CalendarConnection(
  id: id,
  provider: provider,
  memberId: Fixtures.thandiMemberId,
  ownerUid: ownerUid,
  accountLabel: label,
  lastSyncedAt: lastSyncedAt,
);

void main() {
  late FakeCalendarSyncRepository repository;
  late FakeCalendarSyncDirectory directory;
  late FakeLinkOpener opener;

  ConnectedCalendarsController controllerFor({
    String viewerUid = Fixtures.thandiUid,
    bool isAdmin = false,
  }) {
    final controller = ConnectedCalendarsController(
      calendarSyncRepository: repository,
      calendarSyncDirectory: directory,
      linkOpener: opener,
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
      isAdmin: isAdmin,
      now: () => _now,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  setUp(() {
    repository = FakeCalendarSyncRepository();
    directory = FakeCalendarSyncDirectory();
    opener = FakeLinkOpener();
  });

  tearDown(() => repository.close());

  group('what it shows', () {
    test(
      'the connections as the listener has them, in a stable order',
      () async {
        final controller = controllerFor();
        expect(
          controller.connections,
          isA<AsyncLoading<List<CalendarConnection>>>(),
        );
        repository.emitConnections([
          connection(
            id: 'b',
            provider: CalendarProvider.ics,
            label: 'z.example',
          ),
          connection(id: 'a'),
        ]);
        await pumpEventQueue();
        final shown =
            (controller.connections as AsyncData<List<CalendarConnection>>)
                .value;
        expect(shown.map((c) => c.id), ['a', 'b']);
      },
    );

    test('a failed read is a failure the screen can retry', () async {
      final controller = controllerFor();
      repository.failConnectionsWith(const UnavailableFailure());
      await pumpEventQueue();
      expect(
        controller.connections,
        isA<AsyncFailure<List<CalendarConnection>>>(),
      );
    });

    test('which providers this deployment has set up', () async {
      final controller = controllerFor();
      await pumpEventQueue();
      expect(controller.isAvailable(CalendarProvider.google), isTrue);
      expect(controller.isAvailable(CalendarProvider.microsoft), isFalse);
      expect(controller.isAvailable(CalendarProvider.ics), isTrue);
    });

    test('an unanswered availability reads as "try it and see"', () async {
      directory.failAvailabilityWith = const UnavailableFailure();
      final controller = controllerFor();
      await pumpEventQueue();
      expect(
        controller.availability,
        isA<AsyncFailure<ProviderAvailability>>(),
      );
      expect(controller.isAvailable(CalendarProvider.microsoft), isTrue);
    });

    test('how long ago each connection synced, and never before it has', () {
      final controller = controllerFor();
      expect(controller.sinceLastSync(connection()), isNull);
      expect(
        controller.sinceLastSync(
          connection(lastSyncedAt: _now.subtract(const Duration(minutes: 12))),
        ),
        const Duration(minutes: 12),
      );
    });

    test('the feed link as the listener has it', () async {
      final controller = controllerFor();
      repository.emitFeed(const CalendarFeedLink('https://feed.test/x'));
      await pumpEventQueue();
      expect(controller.feed?.url, 'https://feed.test/x');
      expect(controller.feed?.subscription.scheme, 'webcal');
    });
  });

  group('who may manage a connection', () {
    test('its owner and an admin, and nobody else', () {
      final mine = connection();
      expect(controllerFor().canManage(mine), isTrue);
      expect(
        controllerFor(viewerUid: Fixtures.samUid).canManage(mine),
        isFalse,
      );
      expect(
        controllerFor(
          viewerUid: Fixtures.samUid,
          isAdmin: true,
        ).canManage(mine),
        isTrue,
      );
    });
  });

  group('connecting', () {
    test(
      'Google opens its consent page in the browser and says where to finish',
      () async {
        final controller = controllerFor();
        repository.emitConnections([]);
        await pumpEventQueue();
        await controller.connect(CalendarProvider.google);
        expect(directory.started, [CalendarProvider.google]);
        expect(opener.opened, [directory.consentPage]);
        expect(controller.isAwaitingBrowser, isTrue);
        expect(controller.actionFailure, isNull);

        repository.emitConnections([connection()]);
        await pumpEventQueue();
        expect(controller.isAwaitingBrowser, isFalse, reason: 'it came back');
      },
    );

    test('a phone that will not open the page says so, in words', () async {
      opener.opens = false;
      final controller = controllerFor();
      await controller.connect(CalendarProvider.google);
      expect(
        controller.actionFailure,
        isA<CalendarSyncFailure>().having(
          (failure) => failure.problem,
          'problem',
          CalendarSyncProblem.couldNotOpenBrowser,
        ),
      );
      expect(controller.isAwaitingBrowser, isFalse);
    });

    test(
      'a provider that is not set up is refused and held for the banner',
      () async {
        directory.failWith = const CalendarSyncFailure(
          CalendarSyncProblem.providerNotConfigured,
        );
        final controller = controllerFor();
        await controller.connect(CalendarProvider.microsoft);
        expect(controller.actionFailure, isA<CalendarSyncFailure>());
        expect(opener.opened, isEmpty);
      },
    );

    test(
      'a calendar link is trimmed, sent, and reports whether it worked',
      () async {
        final controller = controllerFor();
        expect(
          await controller.connectLink('  webcal://x.example/c.ics  '),
          isTrue,
        );
        expect(directory.linked, ['webcal://x.example/c.ics']);

        directory.failWith = const CalendarSyncFailure(
          CalendarSyncProblem.notACalendarLink,
        );
        expect(await controller.connectLink('https://x.example/page'), isFalse);
        expect(controller.actionFailure, isA<CalendarSyncFailure>());
        expect(await controller.connectLink('   '), isFalse);
      },
    );
  });

  group('managing a connection', () {
    test(
      'sync now and disconnect go to the Functions, one at a time',
      () async {
        final controller = controllerFor();
        final target = connection();
        final first = controller.syncNow(target);
        expect(controller.isBusy(target), isTrue);
        await controller.syncNow(target);
        await first;
        expect(directory.synced, ['c1'], reason: 'the second tap was ignored');
        expect(controller.isBusy(target), isFalse);

        await controller.disconnect(target);
        expect(directory.disconnected, ['c1']);
      },
    );

    test('a refusal is kept for the banner and can be dismissed', () async {
      directory.failWith = const CalendarSyncFailure(
        CalendarSyncProblem.notYourConnection,
      );
      final controller = controllerFor();
      await controller.disconnect(connection());
      expect(controller.actionFailure, isNotNull);
      controller.dismissActionFailure();
      expect(controller.actionFailure, isNull);
    });
  });

  group('the feed', () {
    test(
      'share and reset ask the Functions; the link arrives by the listener',
      () async {
        final controller = controllerFor(isAdmin: true);
        await controller.shareFeed();
        await controller.resetFeed();
        expect(directory.feedsShared, 1);
        expect(directory.feedsReset, 1);
        expect(controller.feed, isNull, reason: 'nothing copied from a reply');
      },
    );

    test('subscribing hands the webcal link to the phone', () async {
      final controller = controllerFor();
      repository.emitFeed(const CalendarFeedLink('https://feed.test/x'));
      await pumpEventQueue();
      await controller.subscribeToFeed();
      expect(opener.opened.single.toString(), 'webcal://feed.test/x');
    });
  });

  test('a status the build does not know reads as needing attention', () {
    final stored = CalendarConnection.fromJson({
      'id': 'c9',
      'provider': 'google',
      'memberId': 'm',
      'ownerUid': 'u',
      'status': 'somethingNewer',
    });
    expect(stored.status, ConnectionStatus.unreachable);
  });
}
