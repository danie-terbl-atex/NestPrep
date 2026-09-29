import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/calendar_week.dart';
import 'package:nestprep/features/calendar/model/day_entry.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/model/synced_event.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/household_fixtures.dart';

/// The week's read of imported events (calendar ADR-0003): it follows the
/// window like the exceptions do, and it never holds the household's own week
/// back. Friday 18 September 2026 in Johannesburg.
final _nowUtc = DateTime.utc(2026, 9, 18, 9);

SyncedEvent _standup(String on) => SyncedEvent(
  id: 'c1_$on',
  connectionId: 'c1',
  provider: CalendarProvider.microsoft,
  memberId: Fixtures.thandiMemberId,
  title: 'Standup',
  date: CalendarDate.parse(on),
  endDate: CalendarDate.parse(on),
  startMinute: 540,
  endMinute: 555,
);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeCalendarRepository repository;
  late FakeCalendarSyncRepository sync;
  late CalendarController controller;

  setUp(() {
    repository = FakeCalendarRepository();
    sync = FakeCalendarSyncRepository();
    controller = CalendarController(
      calendarRepository: repository,
      calendarSyncRepository: sync,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
    await sync.close();
  });

  Future<void> answerTheWeek() async {
    repository
      ..emitEvents([])
      ..emitExceptions([]);
    await pumpEventQueue();
  }

  List<DayEntry> on(String iso) => (controller.week as AsyncData<CalendarWeek>)
      .value
      .on(CalendarDate.parse(iso));

  test('reads imported events for the week it is showing', () {
    expect(sync.syncedWindows.single.from.iso, '2026-09-14');
    expect(sync.syncedWindows.single.to.iso, '2026-09-20');
  });

  test(
    'the household’s week shows before any imported event arrives',
    () async {
      await answerTheWeek();
      expect(controller.week, isA<AsyncData<CalendarWeek>>());
      sync.emitSynced([_standup('2026-09-18')]);
      await pumpEventQueue();
      expect(on('2026-09-18').single, isA<SyncedEntry>());
    },
  );

  test(
    'moving the week reopens the imported read with the new window',
    () async {
      await answerTheWeek();
      controller.goToNextWeek();
      await pumpEventQueue();
      expect(sync.syncedWindows.last.from.iso, '2026-09-21');
      expect(sync.syncedWindows, hasLength(2));
    },
  );

  test('showDay turns to the week a date is in and opens that day', () async {
    await answerTheWeek();
    controller.showDay(CalendarDate(2026, 10, 7));
    expect(controller.weekStart, CalendarDate(2026, 10, 5));
    expect(controller.selectedDay, CalendarDate(2026, 10, 7));
    await pumpEventQueue();
    expect(repository.exceptionWindows.last.from.iso, '2026-10-05');
  });

  test(
    'a failed imported read is a banner, and the week still stands',
    () async {
      await answerTheWeek();
      sync.failSyncedWith(const UnavailableFailure());
      await pumpEventQueue();
      expect(controller.actionFailure, isA<UnavailableFailure>());
      expect(controller.week, isA<AsyncData<CalendarWeek>>());
    },
  );
}
