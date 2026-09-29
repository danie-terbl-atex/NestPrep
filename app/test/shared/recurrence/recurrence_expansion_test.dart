import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/recurrence/recurrence_expansion.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

List<String> expand({
  required String first,
  RecurrenceRule? rule,
  required String from,
  required String to,
}) => expandOccurrences(
  firstDate: CalendarDate.parse(first),
  rule: rule,
  windowStart: CalendarDate.parse(from),
  windowEnd: CalendarDate.parse(to),
).map((date) => date.iso).toList();

void main() {
  group('a thing that does not repeat', () {
    test('happens once, on its own day', () {
      expect(
        expand(first: '2026-09-17', from: '2026-09-14', to: '2026-09-20'),
        ['2026-09-17'],
      );
    });

    test('is absent from a window it does not fall in', () {
      expect(
        expand(first: '2026-09-17', from: '2026-09-18', to: '2026-09-20'),
        isEmpty,
      );
      expect(
        expand(first: '2026-09-17', from: '2026-09-01', to: '2026-09-16'),
        isEmpty,
      );
    });
  });

  group('daily', () {
    test('every day fills the window', () {
      expect(
        expand(
          first: '2026-09-14',
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
          from: '2026-09-14',
          to: '2026-09-17',
        ),
        ['2026-09-14', '2026-09-15', '2026-09-16', '2026-09-17'],
      );
    });

    test(
      'an interval keeps its phase from the first occurrence, not the window',
      () {
        expect(
          expand(
            first: '2026-09-01',
            rule: const RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
              interval: 3,
            ),
            from: '2026-09-14',
            to: '2026-09-22',
          ),
          ['2026-09-16', '2026-09-19', '2026-09-22'],
        );
      },
    );

    test('nothing lands before the first occurrence', () {
      expect(
        expand(
          first: '2026-09-17',
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
          from: '2026-09-14',
          to: '2026-09-18',
        ),
        ['2026-09-17', '2026-09-18'],
      );
    });
  });

  group('weekly', () {
    test(
      'with no weekdays chosen it repeats on the first occurrence\'s day',
      () {
        expect(
          expand(
            first: '2026-09-17',
            rule: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
            from: '2026-09-14',
            to: '2026-10-05',
          ),
          ['2026-09-17', '2026-09-24', '2026-10-01'],
        );
      },
    );

    test('several weekdays across a month boundary', () {
      // Tuesdays and Thursdays through the end of September into October.
      expect(
        expand(
          first: '2026-09-15',
          rule: const RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            weekdays: [DateTime.tuesday, DateTime.thursday],
          ),
          from: '2026-09-22',
          to: '2026-10-08',
        ),
        [
          '2026-09-22',
          '2026-09-24',
          '2026-09-29',
          '2026-10-01',
          '2026-10-06',
          '2026-10-08',
        ],
      );
    });

    test(
      'every second week counts weeks from the first occurrence\'s week',
      () {
        expect(
          expand(
            first: '2026-09-15',
            rule: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
              interval: 2,
              weekdays: [DateTime.tuesday],
            ),
            from: '2026-09-15',
            to: '2026-10-20',
          ),
          ['2026-09-15', '2026-09-29', '2026-10-13'],
        );
      },
    );

    test(
      'occurrences come back in date order whatever order the weekdays are in',
      () {
        expect(
          expand(
            first: '2026-09-14',
            rule: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
              weekdays: [DateTime.friday, DateTime.monday, DateTime.wednesday],
            ),
            from: '2026-09-14',
            to: '2026-09-20',
          ),
          ['2026-09-14', '2026-09-16', '2026-09-18'],
        );
      },
    );
  });

  group('monthly', () {
    test('the same day of each month', () {
      expect(
        expand(
          first: '2026-09-17',
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.monthly),
          from: '2026-09-01',
          to: '2026-12-31',
        ),
        ['2026-09-17', '2026-10-17', '2026-11-17', '2026-12-17'],
      );
    });

    test('the 31st skips every month that has no 31st, and resumes after', () {
      expect(
        expand(
          first: '2026-01-31',
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.monthly),
          from: '2026-01-01',
          to: '2026-08-31',
        ),
        ['2026-01-31', '2026-03-31', '2026-05-31', '2026-07-31', '2026-08-31'],
      );
    });

    test('the 29th of February appears only in a leap year', () {
      expect(
        expand(
          first: '2024-02-29',
          rule: const RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 12,
          ),
          from: '2024-01-01',
          to: '2029-12-31',
        ),
        ['2024-02-29', '2028-02-29'],
      );
    });

    // Found by home care's room routines (home-care ADR-0004): a deep clean on
    // the 29th was "on" the 30th, because the month's occurrence before the
    // window's first day was kept. A week's view starting mid-month showed an
    // occurrence from the week before.
    test('nothing before the window, even in the window’s own month', () {
      expect(
        expand(
          first: '2026-09-29',
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.monthly),
          from: '2026-09-30',
          to: '2026-10-06',
        ),
        isEmpty,
      );
      expect(
        expand(
          first: '2026-08-10',
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.monthly),
          from: '2026-09-14',
          to: '2026-10-12',
        ),
        ['2026-10-10'],
      );
    });

    test('an interval steps whole months', () {
      expect(
        expand(
          first: '2026-01-15',
          rule: const RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 3,
          ),
          from: '2026-01-01',
          to: '2026-12-31',
        ),
        ['2026-01-15', '2026-04-15', '2026-07-15', '2026-10-15'],
      );
    });
  });

  group('an end date', () {
    test('stops the occurrences, inclusive of the end date itself', () {
      expect(
        expand(
          first: '2026-09-14',
          rule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            until: CalendarDate.parse('2026-09-16'),
          ),
          from: '2026-09-14',
          to: '2026-09-20',
        ),
        ['2026-09-14', '2026-09-15', '2026-09-16'],
      );
    });

    test('a rule that ended before the window gives nothing', () {
      expect(
        expand(
          first: '2026-01-01',
          rule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            until: CalendarDate.parse('2026-01-31'),
          ),
          from: '2026-09-14',
          to: '2026-09-20',
        ),
        isEmpty,
      );
    });
  });

  group('a rule this build cannot read', () {
    test('falls back to a single occurrence rather than nothing at all', () {
      const nonsense = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 0,
      );
      expect(nonsense.isExpandable, isFalse);
      expect(
        expand(
          first: '2026-09-17',
          rule: nonsense,
          from: '2026-09-14',
          to: '2026-09-20',
        ),
        ['2026-09-17'],
      );
    });

    test('an out-of-range weekday is not expandable', () {
      expect(
        const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: [0],
        ).isExpandable,
        isFalse,
      );
      expect(
        const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: [8],
        ).isExpandable,
        isFalse,
      );
    });
  });

  group('the window', () {
    test('a backwards window gives nothing rather than looping', () {
      expect(
        expand(
          first: '2026-09-01',
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
          from: '2026-09-20',
          to: '2026-09-14',
        ),
        isEmpty,
      );
    });

    test('a window opening mid-week holds nothing from before it', () {
      // Found by quick add (calendar ADR-0004), the first caller whose window
      // does not open on a Monday: a Tuesday rule asked for Thursday onwards
      // returned the Tuesday before the window, because the weekly walk
      // checked each day against the first occurrence and not the window.
      expect(
        expand(
          first: '2026-09-29',
          rule: const RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            weekdays: [2, 5],
          ),
          from: '2026-10-01',
          to: '2026-10-09',
        ),
        ['2026-10-02', '2026-10-06', '2026-10-09'],
      );
    });

    test('a long-running daily rule costs only the window it is asked for', () {
      final occurrences = expand(
        first: '2000-01-01',
        rule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        from: '2026-09-14',
        to: '2026-09-20',
      );
      expect(occurrences, hasLength(7));
      expect(occurrences.first, '2026-09-14');
    });
  });

  group('the stored shape', () {
    test('a rule survives a round trip through Firestore', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        weekdays: const [DateTime.tuesday, DateTime.thursday],
        until: CalendarDate.parse('2026-12-31'),
      );
      expect(RecurrenceRule.fromJson(rule.toJson()), rule);
      expect(rule.toJson()['until'], '2026-12-31');
    });

    test(
      'a rule written without the optional fields reads with its defaults',
      () {
        final rule = RecurrenceRule.fromJson({'frequency': 'daily'});
        expect(rule.interval, 1);
        expect(rule.weekdays, isEmpty);
        expect(rule.until, isNull);
      },
    );
  });
}
