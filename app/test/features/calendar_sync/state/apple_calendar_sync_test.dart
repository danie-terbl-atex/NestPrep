import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar_sync/model/apple_calendar.dart';
import 'package:nestprep/features/calendar_sync/state/apple_calendar_sync.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_apple_calendar.dart';
import '../../../support/fake_calendar_sync.dart';

const _uid = 'uid-thandi';
const _home = 'home-1';

TimedAppleOccurrence _timed(String id, DateTime start, {String title = 'x'}) =>
    TimedAppleOccurrence(
      id: id,
      title: title,
      start: start,
      end: start.add(const Duration(hours: 1)),
    );

Matcher _refusedWith(CalendarSyncProblem problem) => throwsA(
  isA<CalendarSyncFailure>().having((f) => f.problem, 'problem', problem),
);

void main() {
  late FakeAppleCalendarReader reader;
  late MemoryAppleCalendarLinkStore store;
  late FakeCalendarSyncDirectory directory;
  late DateTime now;
  late AppleCalendarSync sync;

  setUp(() {
    reader = FakeAppleCalendarReader();
    store = MemoryAppleCalendarLinkStore();
    directory = FakeCalendarSyncDirectory();
    now = DateTime(2026, 11, 5, 9);
    sync = AppleCalendarSync(
      reader: reader,
      store: store,
      directory: directory,
      now: () => now,
    );
    reader.found = [_timed('a', DateTime.utc(2026, 11, 6, 7))];
  });

  group('linking', () {
    test('files the chosen calendars and remembers what it sent', () async {
      await sync.link(_uid, _home, ['icloud-family']);

      expect(directory.applePushes.single.link, isTrue);
      expect(directory.applePushes.single.occurrences, reader.found);
      expect(reader.reads.single.calendarIds, ['icloud-family']);
      final link = await store.read(_uid, _home);
      expect(link?.connectionId, directory.appleConnectionId);
      expect(link?.calendarIds, ['icloud-family']);
      expect(link?.digest, AppleCalendarSync.digestOf(reader.found));
      expect(link?.pushedAt, now);
    });

    test('reads a week back and four months ahead of today', () async {
      await sync.link(_uid, _home, ['c']);

      final read = reader.reads.single;
      expect(read.from, DateTime(2026, 10, 28));
      expect(read.to, DateTime(2027, 3, 7));
    });

    test(
      'asks for access the first time, and refuses in words after a no',
      () async {
        reader.current = AppleCalendarAccess.notDetermined;
        reader.answerToRequest = AppleCalendarAccess.denied;

        await expectLater(
          sync.link(_uid, _home, ['c']),
          _refusedWith(CalendarSyncProblem.appleCalendarDenied),
        );
        expect(reader.requests, 1);
        expect(directory.applePushes, isEmpty);
        expect(await store.read(_uid, _home), isNull);
      },
    );

    test('says so when Screen Time blocks calendars', () async {
      reader.current = AppleCalendarAccess.restricted;
      await expectLater(
        sync.link(_uid, _home, ['c']),
        _refusedWith(CalendarSyncProblem.appleCalendarRestricted),
      );
    });

    test('refuses with nothing chosen', () async {
      await expectLater(
        sync.link(_uid, _home, []),
        _refusedWith(CalendarSyncProblem.noAppleCalendarChosen),
      );
    });

    test('sends the earliest thousand, in order', () async {
      final start = DateTime.utc(2026, 11, 6);
      reader.found = [
        for (var i = 1100; i > 0; i--)
          _timed('e$i', start.add(Duration(minutes: i))),
      ];
      await sync.link(_uid, _home, ['c']);

      final sent = directory.applePushes.single.occurrences;
      expect(sent, hasLength(AppleCalendarSync.maxOccurrences));
      expect(sent.first.id, 'e1');
      expect(sent.last.id, 'e1000');
    });
  });

  group('pushing when the app opens', () {
    setUp(() async {
      await sync.link(_uid, _home, ['c']);
      directory.applePushes.clear();
    });

    test(
      'sends nothing when nothing changed and the last push is fresh',
      () async {
        now = now.add(const Duration(hours: 2));
        await sync.pushIfDue(_uid, _home);
        expect(directory.applePushes, isEmpty);
      },
    );

    test('sends a changed calendar, without filing it again', () async {
      reader.found = [_timed('a', DateTime.utc(2026, 11, 6, 8))];
      await sync.pushIfDue(_uid, _home);

      expect(directory.applePushes.single.link, isFalse);
      expect(
        (await store.read(_uid, _home))?.digest,
        AppleCalendarSync.digestOf(reader.found),
      );
    });

    test('sends again after half a day, so the window keeps moving', () async {
      now = now.add(AppleCalendarSync.refreshAfter);
      await sync.pushIfDue(_uid, _home);
      expect(directory.applePushes, hasLength(1));
    });

    test('Sync now sends even when nothing changed', () async {
      await sync.pushIfDue(_uid, _home, force: true);
      expect(directory.applePushes, hasLength(1));
    });

    test('a phone that linked nothing here sends nothing', () async {
      await sync.pushIfDue(_uid, 'another-home', force: true);
      expect(directory.applePushes, isEmpty);
    });

    test('stops quietly once access is turned off in Settings', () async {
      reader.current = AppleCalendarAccess.denied;
      reader.found = [];
      await sync.pushIfDue(_uid, _home);
      expect(directory.applePushes, isEmpty);
      expect(await store.read(_uid, _home), isNotNull);
    });

    test('Sync now with access turned off says why', () async {
      reader.current = AppleCalendarAccess.denied;
      await expectLater(
        sync.pushIfDue(_uid, _home, force: true),
        _refusedWith(CalendarSyncProblem.appleCalendarDenied),
      );
    });

    test('forgets a connection disconnected from another phone', () async {
      directory.failWith = const CalendarSyncFailure(
        CalendarSyncProblem.connectionNotFound,
      );
      await expectLater(
        sync.pushIfDue(_uid, _home, force: true),
        _refusedWith(CalendarSyncProblem.connectionNotFound),
      );
      expect(await store.read(_uid, _home), isNull);
    });

    test('keeps the link through a refusal that is not about it', () async {
      directory.failWith = const UnavailableFailure();
      await expectLater(
        sync.pushIfDue(_uid, _home, force: true),
        throwsA(isA<UnavailableFailure>()),
      );
      expect(await store.read(_uid, _home), isNotNull);
    });

    test('two pushes at once are one', () async {
      reader.found = [_timed('b', DateTime.utc(2026, 11, 7))];
      await Future.wait([
        sync.pushIfDue(_uid, _home),
        sync.pushIfDue(_uid, _home),
      ]);
      expect(directory.applePushes, hasLength(1));
    });
  });
}
