import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// A plan is filed under its ISO week, and product-analytics counts a plan in
/// the same kind of week (`iso_week.ts`). A key that is off by one at a year
/// boundary files a child's January lunches under the wrong week.
void main() {
  group('the week key', () {
    test('is the ISO week the Monday starts', () {
      expect(LunchWeek.of(CalendarDate(2026, 9, 29)).key, '2026-W40');
      expect(LunchWeek.of(CalendarDate(2026, 9, 28)).key, '2026-W40');
      expect(LunchWeek.of(CalendarDate(2026, 10, 4)).key, '2026-W40');
    });

    test('belongs to the year its Thursday is in', () {
      // 31 December 2020 was a Thursday in week 53 of 2020.
      expect(LunchWeek.of(CalendarDate(2020, 12, 31)).key, '2020-W53');
      // 3 January 2021 is a Sunday still in 2020's last week.
      expect(LunchWeek.of(CalendarDate(2021, 1, 3)).key, '2020-W53');
      // 30 December 2024 is the Monday of 2025's first week.
      expect(LunchWeek.of(CalendarDate(2024, 12, 30)).key, '2025-W01');
    });

    test('reads back into the same week', () {
      for (final day in [
        CalendarDate(2026, 9, 29),
        CalendarDate(2020, 12, 31),
        CalendarDate(2024, 12, 30),
        CalendarDate(2027, 1, 1),
      ]) {
        final week = LunchWeek.of(day);
        expect(LunchWeek.parse(week.key), week);
      }
    });

    test('refuses anything that is not a week', () {
      expect(() => LunchWeek.parse('2026-40'), throwsFormatException);
      expect(() => LunchWeek.parse('2026-W54'), throwsFormatException);
      expect(() => LunchWeek.parse(''), throwsFormatException);
    });
  });

  group('a school week', () {
    final week = LunchWeek.of(CalendarDate(2026, 9, 29));

    test('is Monday to Friday', () {
      expect(week.schoolDays.map((day) => day.iso), [
        '2026-09-28',
        '2026-09-29',
        '2026-09-30',
        '2026-10-01',
        '2026-10-02',
      ]);
      expect(week.dayOf(DateTime.friday), CalendarDate(2026, 10, 2));
    });

    test('is prepped the Sunday before', () {
      expect(week.prepDay, CalendarDate(2026, 9, 27));
    });

    test('steps and counts in whole weeks', () {
      expect(week.next.key, '2026-W41');
      expect(week.previous.key, '2026-W39');
      expect(week.shift(-8).weeksUntil(week), 8);
    });
  });

  group('the week somebody plans', () {
    test('is this one on a school day', () {
      expect(LunchWeek.planningFor(CalendarDate(2026, 10, 2)).key, '2026-W40');
    });

    test('is next week from Saturday, when Sunday prep is for it', () {
      expect(LunchWeek.planningFor(CalendarDate(2026, 10, 3)).key, '2026-W41');
      expect(LunchWeek.planningFor(CalendarDate(2026, 10, 4)).key, '2026-W41');
    });
  });
}
