import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/calendar_sync_route.dart';
import 'package:nestprep/features/calendar/model/quick_add/quick_add_result.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/model/synced_event.dart';
import 'package:nestprep/shared/copy/calendar_sync_copy.dart';
import 'package:nestprep/shared/copy/quick_add_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The week, with phase 2 on it (calendar ADR-0003, ADR-0004): quick add from
/// a typed line to a saved event, and events from connected calendars on the
/// agenda, read-only and badged with where they came from. Friday 18 September
/// 2026 in Johannesburg throughout.
final _nowUtc = DateTime.utc(2026, 9, 18, 9);

SyncedEvent _standup({
  String title = 'Standup',
  CalendarProvider provider = CalendarProvider.google,
  String sourceLabel = '',
}) => SyncedEvent(
  id: 'c1_x',
  connectionId: 'c1',
  provider: provider,
  memberId: Fixtures.thandiMemberId,
  sourceLabel: sourceLabel,
  title: title,
  date: CalendarDate(2026, 9, 18),
  endDate: CalendarDate(2026, 9, 18),
  startMinute: 9 * 60,
  endMinute: 9 * 60 + 15,
);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeCalendarRepository repository;
  late FakeCalendarSyncRepository sync;
  late CalendarController controller;

  setUp(() {
    repository = FakeCalendarRepository();
    sync = FakeCalendarSyncRepository();
  });

  tearDown(() async {
    await repository.close();
    await sync.close();
  });

  /// The controller is made inside the test, not in `setUp`: moving a week
  /// cancels and reopens its listeners, and a subscription opened outside the
  /// test's fake clock completes its cancel on a clock nothing advances.
  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    controller = CalendarController(
      calendarRepository: repository,
      calendarSyncRepository: sync,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
    addTearDown(controller.dispose);
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => CalendarScreen(onSelectTab: (_) {}),
          ),
          GoRoute(
            path: CalendarSyncRoute.path,
            builder: (context, state) => const Text(
              CalendarSyncCopy.title,
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<CalendarController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
    repository
      ..emitEvents([])
      ..emitExceptions([]);
    await tester.pumpAndSettle();
  }

  /// After the week moves: the old listeners' cancel completes on the real
  /// clock, not the test's fake one, so it is given a real turn before the
  /// new window's read is answered and the screen can settle.
  Future<void> reopenWindow(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    repository.emitExceptions([]);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String line) async {
    await tester.tap(find.text(QuickAddCopy.hint));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, line);
    await tester.pumpAndSettle();
  }

  Future<void> tapInSheet(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('quick add', () {
    testWidgets('"Soccer Tuesdays at 5" is previewed, then saved as weekly', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, 'Soccer Tuesdays at 5');

      expect(find.text('Soccer'), findsOneWidget);
      expect(find.text('Tue 22 Sep'), findsOneWidget);
      expect(find.text('17:00 – 18:00'), findsOneWidget);
      expect(find.text('Every Tue'), findsOneWidget);
      expect(repository.savedEvents, isEmpty, reason: 'nothing until Add');

      // The week turns to where it landed and reopens that window's read, so
      // it is answered before the screen can settle.
      await tester.ensureVisible(find.text(QuickAddCopy.add).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(QuickAddCopy.add).last);
      await tester.pump();
      await reopenWindow(tester);
      expect(repository.savedEvents.single.title, 'Soccer');
      expect(repository.savedEvents.single.startMinute, 17 * 60);
      expect(
        controller.selectedDay,
        CalendarDate(2026, 9, 22),
        reason: 'the week turns to where it landed',
      );
    });

    testWidgets(
      'a line it cannot place says what is missing, and offers no Add',
      (tester) async {
        await pump(tester);
        await type(tester, 'Soccer');
        expect(
          find.text(QuickAddCopy.problem(QuickAddProblem.noWhen)),
          findsOneWidget,
        );
        expect(find.text(QuickAddCopy.add), findsNothing);
      },
    );

    testWidgets('Edit opens the full sheet already filled in', (tester) async {
      await pump(tester);
      await type(tester, 'Dentist 3 March 10:30 for Thandi');
      // In the preview, and among the filter's names under the sheet.
      expect(find.text('Thandi Helper'), findsNWidgets(2));
      await tapInSheet(tester, QuickAddCopy.edit);

      expect(find.widgetWithText(TextField, 'Dentist'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
      await tester.ensureVisible(find.text('Save').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save').last);
      await reopenWindow(tester);
      expect(repository.savedEvents.single.title, 'Dentist');
      expect(repository.savedEvents.single.startMinute, 10 * 60 + 30);
    });
  });

  group('events from connected calendars', () {
    testWidgets(
      'sit in the day by their time, badged with where they came from',
      (tester) async {
        await pump(tester);
        sync.emitSynced([_standup()]);
        await tester.pumpAndSettle();

        expect(find.text('Standup'), findsOneWidget);
        expect(find.text('09:00 – 09:15 · Thandi Helper'), findsOneWidget);
        expect(find.text('Google'), findsOneWidget);
      },
    );

    testWidgets('an iCloud link is Apple’s, and an untitled one is Busy', (
      tester,
    ) async {
      await pump(tester);
      sync.emitSynced([
        _standup(
          title: '',
          provider: CalendarProvider.ics,
          sourceLabel: 'p01-caldav.icloud.com',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text(CalendarSyncCopy.syncedBusy), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('tapping one says where to change it, and goes there', (
      tester,
    ) async {
      await pump(tester);
      sync.emitSynced([_standup()]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Standup'));
      await tester.pumpAndSettle();

      expect(find.text(CalendarSyncCopy.syncedReadOnlyBody), findsOneWidget);
      await tapInSheet(tester, CalendarSyncCopy.openFromWeek);
      expect(find.text(CalendarSyncCopy.title), findsOneWidget);
    });

    testWidgets('are hidden by the member filter like anything else', (
      tester,
    ) async {
      await pump(tester);
      sync.emitSynced([_standup()]);
      controller.filterBy(Fixtures.samMemberId);
      await tester.pumpAndSettle();
      expect(find.text('Standup'), findsNothing);
    });

    testWidgets('a failed read leaves the household’s own week standing', (
      tester,
    ) async {
      await pump(tester);
      sync.failSyncedWith(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(controller.actionFailure, isA<UnavailableFailure>());
      expect(find.text(QuickAddCopy.hint), findsOneWidget);
    });
  });

  testWidgets('quick add and an imported event hold at 200% text in dark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    sync.emitSynced([_standup()]);
    await tester.pumpAndSettle();
    await type(
      tester,
      'Swimming every other Thursday 4pm until December for Thandi',
    );

    expect(tester.takeException(), isNull);
  });
}
