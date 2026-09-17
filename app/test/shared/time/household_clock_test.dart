import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('the day an instant falls on', () {
    test('is the household\'s day, not UTC\'s', () {
      // 22:30 UTC is already the next day in Johannesburg (UTC+2).
      final instant = DateTime.utc(2026, 9, 17, 22, 30);
      expect(
        HouseholdClock('Africa/Johannesburg').dateOf(instant).iso,
        '2026-09-18',
      );
      expect(HouseholdClock('UTC').dateOf(instant).iso, '2026-09-17');
    });

    test('is the household\'s day when the household is behind UTC', () {
      // 02:00 UTC is still the previous evening in New York.
      final instant = DateTime.utc(2026, 9, 18, 2);
      expect(
        HouseholdClock('America/New_York').dateOf(instant).iso,
        '2026-09-17',
      );
    });

    test('reads the same instant however the caller expressed it', () {
      final clock = HouseholdClock('Africa/Johannesburg');
      final utc = DateTime.utc(2026, 9, 17, 22, 30);
      expect(clock.dateOf(utc.toLocal()), clock.dateOf(utc));
    });
  });

  group('daylight saving', () {
    test('a household that observes it gets the right day on both sides', () {
      final clock = HouseholdClock('Europe/London');
      // BST: 23:30 UTC in July is already the 18th in London.
      expect(clock.dateOf(DateTime.utc(2026, 7, 17, 23, 30)).iso, '2026-07-18');
      // GMT: the same clock time in January is still the 17th.
      expect(clock.dateOf(DateTime.utc(2026, 1, 17, 23, 30)).iso, '2026-01-17');
    });

    test('midnight is a different instant in summer and in winter', () {
      final clock = HouseholdClock('Europe/London');
      expect(
        clock.startOfDay(CalendarDate(2026, 7, 17)),
        DateTime.utc(2026, 7, 16, 23),
      );
      expect(
        clock.startOfDay(CalendarDate(2026, 1, 17)),
        DateTime.utc(2026, 1, 17),
      );
    });
  });

  group('the bounds of a day', () {
    test('start and end bracket the household\'s day exactly', () {
      final clock = HouseholdClock('Africa/Johannesburg');
      final date = CalendarDate(2026, 9, 17);
      expect(clock.startOfDay(date), DateTime.utc(2026, 9, 16, 22));
      expect(clock.endOfDay(date), DateTime.utc(2026, 9, 17, 22));
      expect(clock.dateOf(clock.startOfDay(date)), date);
      // The end is exclusive: it is already the next day.
      expect(clock.dateOf(clock.endOfDay(date)), date.addDays(1));
    });
  });

  group('a wall-clock time', () {
    test('resolves to the instant it means where the household lives', () {
      final clock = HouseholdClock('Africa/Johannesburg');
      expect(
        clock.instantAt(CalendarDate(2026, 9, 17), hour: 8, minute: 30),
        DateTime.utc(2026, 9, 17, 6, 30),
      );
    });

    test('round-trips back to the same wall-clock time', () {
      final clock = HouseholdClock('America/New_York');
      final instant = clock.instantAt(
        CalendarDate(2026, 9, 17),
        hour: 14,
        minute: 45,
      );
      expect(clock.minutesOfDay(instant), (14 * 60) + 45);
      expect(clock.dateOf(instant).iso, '2026-09-17');
    });
  });

  group('today', () {
    test('is read from the clock the household is given', () {
      final clock = HouseholdClock(
        'Africa/Johannesburg',
        now: () => DateTime.utc(2026, 9, 17, 22, 30),
      );
      expect(clock.today.iso, '2026-09-18');
    });
  });

  group('a zone this build does not know', () {
    test('falls back to UTC rather than losing the calendar', () {
      final clock = HouseholdClock('Mars/Olympus_Mons');
      expect(clock.dateOf(DateTime.utc(2026, 9, 17, 22, 30)).iso, '2026-09-17');
    });
  });
}
