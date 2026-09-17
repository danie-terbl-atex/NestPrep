import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/calendar_week.dart';
import 'package:nestprep/features/calendar/model/event_exception.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/household_fixtures.dart';

/// 22:30 UTC on Thursday the 17th is already Friday the 18th in Johannesburg.
final _nowUtc = DateTime.utc(2026, 9, 17, 22, 30);

CalendarDate date(String iso) => CalendarDate.parse(iso);

HouseholdEvent event({
  String id = 'e1',
  String title = 'School run',
  String on = '2026-09-18',
  int? startMinute = 450,
  RecurrenceRule? recurrence,
  List<String> memberIds = const [],
}) => HouseholdEvent(
  id: id,
  title: title,
  date: date(on),
  startMinute: startMinute,
  endMinute: startMinute == null ? null : startMinute + 60,
  recurrence: recurrence,
  memberIds: memberIds,
  createdBy: Fixtures.samMemberId,
);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeCalendarRepository repository;
  late CalendarController controller;

  setUp(() {
    repository = FakeCalendarRepository();
    controller = CalendarController(
      calendarRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => _nowUtc,
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  CalendarWeek weekOf() {
    final state = controller.week;
    expect(state, isA<AsyncData<CalendarWeek>>());
    return (state as AsyncData<CalendarWeek>).value;
  }

  Future<void> emit({
    List<HouseholdEvent> events = const [],
    List<EventException> exceptions = const [],
  }) async {
    repository.emitEvents(events);
    repository.emitExceptions(exceptions);
    await pumpEventQueue();
  }

  test('opens on the household"s current week, starting Monday', () {
    // The 18th is a Friday in Johannesburg; its week starts Monday the 14th.
    expect(controller.today.iso, '2026-09-18');
    expect(controller.weekStart.iso, '2026-09-14');
  });

  test('windows the exceptions read to the week it is showing', () {
    expect(repository.exceptionWindows.single.from.iso, '2026-09-14');
    expect(repository.exceptionWindows.single.to.iso, '2026-09-20');
  });

  test('moving a week reopens only that read, with the new window', () async {
    controller.goToNextWeek();
    // The old listener is cancelled before the new one opens, so the reopen is
    // a microtask later — the week shows its loading state until then.
    expect(controller.week, isA<AsyncLoading<CalendarWeek>>());
    await pumpEventQueue();

    expect(repository.exceptionWindows.last.from.iso, '2026-09-21');
    expect(repository.exceptionWindows.last.to.iso, '2026-09-27');
    expect(repository.exceptionWindows, hasLength(2));
  });

  test('stays loading until both reads have answered', () async {
    expect(controller.week, isA<AsyncLoading<CalendarWeek>>());
    repository.emitEvents([event()]);
    await pumpEventQueue();
    expect(controller.week, isA<AsyncLoading<CalendarWeek>>());
    repository.emitExceptions([]);
    await pumpEventQueue();
    expect(controller.week, isA<AsyncData<CalendarWeek>>());
  });

  test('groups the week into seven days, whether or not anything is on', () async {
    await emit(events: [event()]);
    expect(weekOf().days.map((d) => d.iso).first, '2026-09-14');
    expect(weekOf().days, hasLength(7));
    expect(weekOf().on(date('2026-09-18')), hasLength(1));
    expect(weekOf().on(date('2026-09-17')), isEmpty);
  });

  test('selects today when today is in the week, and the Monday when it is not', () async {
    await emit();
    expect(controller.selectedDay.iso, '2026-09-18');

    controller.goToNextWeek();
    await pumpEventQueue();
    repository.emitExceptions([]);
    await pumpEventQueue();
    expect(controller.selectedDay.iso, '2026-09-21');
  });

  test('filters by member, and the filter survives the week moving', () async {
    await emit(
      events: [
        event(id: 'a', title: 'Mine', memberIds: [Fixtures.samMemberId]),
        event(id: 'b', title: 'Theirs', memberIds: [Fixtures.kidMemberId]),
      ],
    );
    expect(weekOf().on(date('2026-09-18')), hasLength(2));

    controller.filterBy(Fixtures.kidMemberId);
    expect(
      weekOf().on(date('2026-09-18')).map((o) => o.event.title),
      ['Theirs'],
    );
    expect(controller.memberFilter, Fixtures.kidMemberId);
  });

  test('a skipped occurrence is gone from the week and no other', () async {
    await emit(
      events: [
        event(
          on: '2026-09-14',
          recurrence: const RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        ),
      ],
      exceptions: [
        EventException(
          id: EventException.idFor('e1', date('2026-09-16')),
          eventId: 'e1',
          occurrenceDate: date('2026-09-16'),
          skippedBy: Fixtures.samMemberId,
        ),
      ],
    );
    expect(weekOf().on(date('2026-09-16')), isEmpty);
    expect(weekOf().on(date('2026-09-15')), hasLength(1));
  });

  test('skipping asks for that occurrence only', () async {
    await emit(events: [event()]);
    final occurrence = weekOf().on(date('2026-09-18')).single;
    await controller.skip(occurrence);

    expect(repository.skipped.single.eventId, 'e1');
    expect(repository.skipped.single.date.iso, '2026-09-18');
  });

  test('refuses to save an event with no title', () async {
    await controller.saveEvent(
      title: '  ',
      date: controller.today,
      memberIds: const [],
    );
    expect(repository.savedEvents, isEmpty);
  });

  test('saves an all-day event as one with no times', () async {
    await controller.saveEvent(
      title: 'Birthday',
      date: controller.today,
      memberIds: const [],
    );
    expect(repository.savedEvents.single.startMinute, isNull);
  });

  test('a refused write becomes copy, and clears', () async {
    await emit(events: [event()]);
    repository.failWritesWith = const PermissionDeniedFailure();
    await controller.deleteEvent('e1');
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());

    controller.dismissActionFailure();
    expect(controller.actionFailure, isNull);
  });

  test('a read that fails becomes a failure state with a way back', () async {
    repository.failEventsWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.week, isA<AsyncFailure<CalendarWeek>>());

    await controller.retry();
    expect(controller.week, isA<AsyncLoading<CalendarWeek>>());
  });

  test('going back to this week lands on the week that holds today', () {
    controller.goToNextWeek();
    controller.goToNextWeek();
    expect(controller.weekStart.iso, '2026-09-28');

    controller.goToThisWeek();
    expect(controller.weekStart.iso, '2026-09-14');
  });
}
