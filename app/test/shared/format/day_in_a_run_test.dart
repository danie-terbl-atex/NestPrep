import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/format/nest_dates.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Two ways to name a day, and the rule for which is which.
///
/// A date on its own reads better as "Today". A column of consecutive days does
/// not: one row saying *Yesterday* between rows saying *Mon 14 Sep* is two
/// systems at once, and the eye loses the thread.
void main() {
  final today = CalendarDate.parse('2026-09-18');
  final yesterday = CalendarDate.parse('2026-09-17');
  final tomorrow = CalendarDate.parse('2026-09-19');

  group('on its own, a date is relative', () {
    test('today, yesterday and tomorrow have names', () {
      expect(NestDates.relative(today, today), AppCopy.dateToday);
      expect(NestDates.relative(yesterday, today), AppCopy.dateYesterday);
      expect(NestDates.relative(tomorrow, today), AppCopy.dateTomorrow);
    });

    test('anything further away is just the date', () {
      final farOff = CalendarDate.parse('2026-09-14');
      expect(NestDates.relative(farOff, today), NestDates.full(farOff, today));
    });
  });

  group('in a run of days, every day is the date', () {
    test('including the three that have names of their own', () {
      for (final date in [yesterday, today, tomorrow]) {
        expect(
          NestDates.dayInARun(date, today),
          NestDates.full(date, today),
          reason: '${date.iso} must not become a word in a column of dates',
        );
      }
    });

    test('a whole week reads as one system, not two', () {
      final monday = CalendarDate.parse('2026-09-14');
      final labels = [
        for (var i = 0; i < 7; i++)
          NestDates.dayInARun(monday.addDays(i), today),
      ];

      for (final word in [
        AppCopy.dateToday,
        AppCopy.dateYesterday,
        AppCopy.dateTomorrow,
      ]) {
        expect(
          labels,
          isNot(contains(word)),
          reason: '"$word" among six dates is the mixture this rule exists for',
        );
      }
      expect(labels.toSet(), hasLength(7), reason: 'seven distinct days');
    });
  });
}
