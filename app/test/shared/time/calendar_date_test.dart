import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

void main() {
  group('parsing', () {
    test('reads a YYYY-MM-DD date back as the same day', () {
      final date = CalendarDate.parse('2026-09-17');
      expect((date.year, date.month, date.day), (2026, 9, 17));
      expect(date.iso, '2026-09-17');
    });

    test('refuses anything that is not a calendar date', () {
      for (final bad in [
        '2026-9-17',
        '17-09-2026',
        '2026-09-17T00:00:00',
        '',
      ]) {
        expect(
          () => CalendarDate.parse(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });

    test('refuses a day the calendar does not have', () {
      expect(() => CalendarDate.parse('2026-02-30'), throwsFormatException);
      expect(() => CalendarDate.parse('2026-13-01'), throwsFormatException);
      expect(CalendarDate.parse('2024-02-29').iso, '2024-02-29');
    });
  });

  group('arithmetic', () {
    test('adding days crosses a month and a year boundary', () {
      expect(CalendarDate(2026, 1, 31).addDays(1).iso, '2026-02-01');
      expect(CalendarDate(2026, 12, 31).addDays(1).iso, '2027-01-01');
      expect(CalendarDate(2026, 3, 1).addDays(-1).iso, '2026-02-28');
    });

    test('a month too short for the day has no such date', () {
      expect(CalendarDate(2026, 1, 31).addMonthsKeepingDay(1), isNull);
      expect(
        CalendarDate(2026, 1, 31).addMonthsKeepingDay(2)?.iso,
        '2026-03-31',
      );
      expect(
        CalendarDate(2026, 1, 15).addMonthsKeepingDay(12)?.iso,
        '2027-01-15',
      );
    });

    test('the week starts on Monday', () {
      expect(CalendarDate(2026, 9, 17).weekday, DateTime.thursday);
      expect(CalendarDate(2026, 9, 17).weekStart.iso, '2026-09-14');
      expect(CalendarDate(2026, 9, 14).weekStart.iso, '2026-09-14');
      expect(CalendarDate(2026, 9, 20).weekStart.iso, '2026-09-14');
    });

    test('days between two dates counts whole days in both directions', () {
      expect(CalendarDate(2026, 9, 14).daysUntil(CalendarDate(2026, 9, 17)), 3);
      expect(
        CalendarDate(2026, 9, 17).daysUntil(CalendarDate(2026, 9, 14)),
        -3,
      );
    });
  });

  group('ordering', () {
    test('two dates for the same day are the same value', () {
      expect(CalendarDate(2026, 9, 17), CalendarDate.parse('2026-09-17'));
      expect(
        CalendarDate(2026, 9, 17).hashCode,
        CalendarDate.parse('2026-09-17').hashCode,
      );
    });

    test('a range includes both of its ends', () {
      final from = CalendarDate(2026, 9, 14);
      final to = CalendarDate(2026, 9, 20);
      expect(from.isInRange(from, to), isTrue);
      expect(to.isInRange(from, to), isTrue);
      expect(CalendarDate(2026, 9, 13).isInRange(from, to), isFalse);
      expect(CalendarDate(2026, 9, 21).isInRange(from, to), isFalse);
    });
  });
}
