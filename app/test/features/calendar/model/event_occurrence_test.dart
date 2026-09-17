import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/event_exception.dart';
import 'package:nestprep/features/calendar/model/event_occurrence.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/household_fixtures.dart';

CalendarDate date(String iso) => CalendarDate.parse(iso);

HouseholdEvent event({
  String id = 'e1',
  String title = 'School run',
  String on = '2026-09-22',
  int? startMinute = 450,
  int? endMinute = 510,
  RecurrenceRule? recurrence,
  List<String> memberIds = const [],
}) => HouseholdEvent(
  id: id,
  title: title,
  date: date(on),
  startMinute: startMinute,
  endMinute: endMinute,
  recurrence: recurrence,
  memberIds: memberIds,
  createdBy: Fixtures.samMemberId,
);

void main() {
  group('an event', () {
    test('is all-day exactly when it has no start time', () {
      expect(event(startMinute: null, endMinute: null).isAllDay, isTrue);
      expect(event().isAllDay, isFalse);
    });

    test('is for everyone when it names nobody', () {
      expect(event().isForEveryone, isTrue);
      expect(event().isFor(Fixtures.kidMemberId), isTrue);
      expect(
        event(memberIds: [Fixtures.kidMemberId]).isFor(Fixtures.samMemberId),
        isFalse,
      );
    });

    test('knows how long it lasts, including past midnight', () {
      expect(event().durationMinutes, 60);
      // 23:00 to 01:00 is two hours, not minus twenty-two.
      expect(event(startMinute: 1380, endMinute: 60).durationMinutes, 120);
      expect(event(startMinute: null, endMinute: null).durationMinutes, isNull);
    });
  });

  group('a window of days', () {
    test('has the event on the days its rule lands on', () {
      final occurrences = selectEventOccurrences(
        events: [
          event(
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
            ),
          ),
        ],
        exceptions: [],
        from: date('2026-09-21'),
        to: date('2026-10-11'),
      );
      expect(occurrences.map((o) => o.date.iso), [
        '2026-09-22',
        '2026-09-29',
        '2026-10-06',
      ]);
    });

    test('renders a Tue/Thu rule across a month boundary on the right days', () {
      final occurrences = selectEventOccurrences(
        events: [
          event(
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
              weekdays: [DateTime.tuesday, DateTime.thursday],
            ),
          ),
        ],
        exceptions: [],
        from: date('2026-09-28'),
        to: date('2026-10-04'),
      );
      expect(occurrences.map((o) => o.date.iso), ['2026-09-29', '2026-10-01']);
    });

    test('hides only the occurrence somebody skipped', () {
      final occurrences = selectEventOccurrences(
        events: [
          event(
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
            ),
          ),
        ],
        exceptions: [
          EventException(
            id: EventException.idFor('e1', date('2026-09-29')),
            eventId: 'e1',
            occurrenceDate: date('2026-09-29'),
            skippedBy: Fixtures.samMemberId,
          ),
        ],
        from: date('2026-09-21'),
        to: date('2026-10-11'),
      );
      expect(occurrences.map((o) => o.date.iso), ['2026-09-22', '2026-10-06']);
    });

    test('puts all-day events first, then by time, then by title', () {
      final occurrences = selectEventOccurrences(
        events: [
          event(id: 'a', title: 'Dentist', startMinute: 600, endMinute: 660),
          event(id: 'b', title: 'Birthday', startMinute: null, endMinute: null),
          event(id: 'c', title: 'Aardvark', startMinute: 600, endMinute: 660),
        ],
        exceptions: [],
        from: date('2026-09-21'),
        to: date('2026-09-27'),
      );
      expect(occurrences.map((o) => o.event.title), [
        'Birthday',
        'Aardvark',
        'Dentist',
      ]);
    });

    test('has nothing in a window the event does not reach', () {
      expect(
        selectEventOccurrences(
          events: [event()],
          exceptions: [],
          from: date('2026-10-05'),
          to: date('2026-10-11'),
        ),
        isEmpty,
      );
    });
  });

  group('the stored shape', () {
    test('keeps the household"s wall clock, not an instant', () {
      final json = event().toJson();
      expect(json['startMinute'], 450);
      expect(json['date'], '2026-09-22');
      expect(json.containsKey('id'), isFalse);
    });

    test('reads an older document that predates the note field', () {
      final parsed = HouseholdEvent.fromJson({
        'id': 'e1',
        'title': 'School run',
        'date': '2026-09-22',
        'createdBy': Fixtures.samMemberId,
      });
      expect(parsed.isAllDay, isTrue);
      expect(parsed.note, isNull);
      expect(parsed.memberIds, isEmpty);
    });
  });
}
