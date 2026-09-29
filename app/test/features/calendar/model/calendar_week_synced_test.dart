import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/calendar_week.dart';
import 'package:nestprep/features/calendar/model/day_entry.dart';
import 'package:nestprep/features/calendar/model/event_occurrence.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/model/synced_event.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/household_fixtures.dart';

/// Imported events on the week (calendar ADR-0003): a sealed entry of their
/// own, merged into each day by the time they start, spanning the days an
/// all-day one covers, and filtered like anything else.
CalendarDate day(String iso) => CalendarDate.parse(iso);

final monday = day('2026-09-28');

SyncedEvent synced(
  String id, {
  String on = '2026-09-29',
  String? until,
  int? start,
  String member = Fixtures.thandiMemberId,
}) => SyncedEvent(
  id: id,
  connectionId: 'c1',
  provider: CalendarProvider.google,
  memberId: member,
  title: id,
  date: day(on),
  endDate: day(until ?? on),
  startMinute: start,
  endMinute: start == null ? null : start + 30,
);

EventOccurrence own(String title, int? start, {String on = '2026-09-29'}) =>
    EventOccurrence(
      event: HouseholdEvent(
        id: title,
        title: title,
        date: day(on),
        startMinute: start,
        endMinute: start == null ? null : start + 60,
        createdBy: Fixtures.samMemberId,
      ),
      date: day(on),
    );

String label(DayEntry entry) => switch (entry) {
  EventEntry(:final occurrence) => 'own:${occurrence.event.title}',
  SyncedEntry(:final event) => 'synced:${event.title}',
  BirthdayEntry() => 'birthday',
};

void main() {
  test('a day reads in time order, the household’s own first at a tie', () {
    final week = CalendarWeek.from(
      occurrences: [own('Holiday', null), own('Run', 450), own('Dentist', 600)],
      synced: [
        synced('Standup', start: 540),
        synced('Early', start: 420),
        synced('Also at ten', start: 600),
        synced('Late', start: 1200),
      ],
      weekStart: monday,
      today: monday,
    );
    expect(week.on(day('2026-09-29')).map(label), [
      'own:Holiday',
      'synced:Early',
      'own:Run',
      'synced:Standup',
      'own:Dentist',
      'synced:Also at ten',
      'synced:Late',
    ]);
  });

  test('an all-day span shows on every day of it inside the week', () {
    final week = CalendarWeek.from(
      occurrences: const [],
      synced: [synced('Half term', on: '2026-09-24', until: '2026-09-30')],
      weekStart: monday,
      today: monday,
    );
    final days = [
      for (final date in week.days)
        if (week.on(date).isNotEmpty) date.iso,
    ];
    expect(days, ['2026-09-28', '2026-09-29', '2026-09-30']);
    expect(
      week.on(day('2026-09-28')).single.key,
      isNot(week.on(day('2026-09-29')).single.key),
      reason: 'each day is its own row with its own key',
    );
  });

  test('a timed event past midnight shows on the day it starts', () {
    final event = synced('Late show', until: '2026-09-30', start: 1380);
    expect(event.daysWithin(monday, monday.addDays(6)), [day('2026-09-29')]);
  });

  test('the member filter keeps only the chosen member’s imported events', () {
    final week = CalendarWeek.from(
      occurrences: const [],
      synced: [
        synced('Theirs'),
        synced('Mine', member: Fixtures.samMemberId),
      ],
      weekStart: monday,
      today: monday,
      memberFilter: Fixtures.samMemberId,
    );
    expect(week.on(day('2026-09-29')).map(label), ['synced:Mine']);
  });
}
