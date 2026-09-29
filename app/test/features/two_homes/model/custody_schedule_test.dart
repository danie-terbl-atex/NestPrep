import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/two_homes/model/custody_days.dart';
import 'package:nestprep/features/two_homes/model/custody_presets.dart';
import 'package:nestprep/features/two_homes/model/custody_schedule.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/two_homes_model_fixtures.dart';

/// The parenting schedule (household ADR-0004): presets written out as
/// blocks, each block a weekly recurrence rule, expanded by the recurrence
/// model into days — with accepted swaps winning, and a handover wherever
/// the home changes.
void main() {
  final monday = CalendarDate(2026, 9, 28);
  const a = CustodySide.a;
  const b = CustodySide.b;

  List<CustodySide?> sidesOf(CustodySchedule schedule, {int days = 14}) {
    final sides = custodySidesBetween(
      schedule: schedule,
      overrides: const {},
      from: schedule.startsOn,
      to: schedule.startsOn.addDays(days - 1),
    );
    return [
      for (var day = 0; day < days; day++)
        sides[schedule.startsOn.addDays(day)],
    ];
  }

  group('the presets', () {
    test('alternating weeks changing on Monday is a week in each home', () {
      final schedule = CustodyPresets.alternatingWeeks(
        startsOn: monday,
        first: a,
      );
      expect(schedule.isComplete, isTrue);
      expect(sidesOf(schedule), [...List.filled(7, a), ...List.filled(7, b)]);
    });

    test('alternating weeks changing on Friday moves the change there', () {
      expect(sidesOf(fixtureSchedule), [
        b,
        b,
        b,
        b,
        a,
        a,
        a,
        a,
        a,
        a,
        a,
        b,
        b,
        b,
      ]);
    });

    test('2-2-3 is two, two, three and then the other way round', () {
      final schedule = CustodyPresets.twoTwoThree(startsOn: monday, first: a);
      expect(schedule.isComplete, isTrue);
      expect(sidesOf(schedule), [a, a, b, b, a, a, a, b, b, a, a, b, b, b]);
    });

    test('every other weekend keeps the weekdays in one home', () {
      final schedule = CustodyPresets.everyOtherWeekend(
        startsOn: monday,
        primary: a,
      );
      expect(schedule.isComplete, isTrue);
      expect(sidesOf(schedule), [a, a, a, a, b, b, b, a, a, a, a, a, a, a]);
    });

    test('a custom fortnight is exactly what was tapped', () {
      final days = [a, b, a, b, a, b, a, b, a, b, a, b, a, b];
      final schedule = CustodyPresets.fromCycle(
        pattern: CustodyPattern.custom,
        startsOn: monday,
        days: days,
      );
      expect(schedule.isComplete, isTrue);
      expect(sidesOf(schedule), days);
      expect(schedule.cycle, days);
    });

    test('a start that is not a Monday is moved to its Monday', () {
      final schedule = CustodyPresets.twoTwoThree(
        startsOn: CalendarDate(2026, 10, 1),
        first: a,
      );
      expect(schedule.startsOn, monday);
    });
  });

  group('the blocks are the recurrence model', () {
    test('each block is weekly, every cycle-length weeks, from its week', () {
      final rules = fixtureSchedule.rules;
      expect(rules, hasLength(4));
      for (final block in rules) {
        expect(block.rule.frequency, RecurrenceFrequency.weekly);
        expect(block.rule.interval, 2);
        expect(block.firstDate.weekday, DateTime.monday);
      }
      expect(rules.map((block) => block.firstDate).toSet(), {
        monday,
        monday.addDays(7),
      });
    });

    test('the cycle repeats for ever: week three is week one again', () {
      final far = custodySidesBetween(
        schedule: fixtureSchedule,
        overrides: const {},
        from: monday.addDays(14 * 20),
        to: monday.addDays(14 * 20 + 13),
      );
      expect([
        for (var day = 0; day < 14; day++) far[monday.addDays(14 * 20 + day)],
      ], sidesOf(fixtureSchedule));
    });

    test('nothing before the schedule starts', () {
      final before = custodySidesBetween(
        schedule: fixtureSchedule,
        overrides: const {},
        from: monday.addDays(-7),
        to: monday.addDays(-1),
      );
      expect(before, isEmpty);
    });
  });

  group('an incomplete schedule is caught before it is sent', () {
    CustodySchedule withBlocks(List<CustodyBlock> blocks, {int weeks = 1}) =>
        CustodySchedule(
          pattern: CustodyPattern.custom,
          startsOn: monday,
          cycleWeeks: weeks,
          blocks: blocks,
        );

    test('a hole', () {
      expect(
        withBlocks(const [
          CustodyBlock(side: a, weekOffset: 0, weekdays: [1, 2, 3]),
          CustodyBlock(side: b, weekOffset: 0, weekdays: [5, 6, 7]),
        ]).isComplete,
        isFalse,
      );
    });

    test('an overlap', () {
      expect(
        withBlocks(const [
          CustodyBlock(side: a, weekOffset: 0, weekdays: [1, 2, 3, 4]),
          CustodyBlock(side: b, weekOffset: 0, weekdays: [4, 5, 6, 7]),
        ]).isComplete,
        isFalse,
      );
    });

    test('a week the cycle does not have, or a start that is not Monday', () {
      expect(
        withBlocks(const [
          CustodyBlock(side: a, weekOffset: 1, weekdays: [1, 2, 3, 4, 5, 6, 7]),
        ]).isComplete,
        isFalse,
      );
      expect(
        fixtureSchedule.copyWith(startsOn: monday.addDays(1)).isComplete,
        isFalse,
      );
    });
  });

  group('days and handovers', () {
    test('a handover is the day the home changes', () {
      final days = custodyDaysBetween(
        schedule: fixtureSchedule,
        overrides: const {},
        from: monday,
        to: monday.addDays(13),
      );
      expect(
        [
          for (final day in days)
            if (day.isHandover) day.date,
        ],
        [CalendarDate(2026, 10, 2), CalendarDate(2026, 10, 9)],
      );
    });

    test('the first day of a window is a handover when it should be', () {
      final days = custodyDaysBetween(
        schedule: fixtureSchedule,
        overrides: const {},
        from: CalendarDate(2026, 10, 2),
        to: CalendarDate(2026, 10, 2),
      );
      expect(days.single.isHandover, isTrue);
      expect(days.single.side, a);
    });

    test(
      'an accepted swap wins over the schedule, and moves the handovers',
      () {
        final days = custodyDaysBetween(
          schedule: fixtureSchedule,
          overrides: const {'2026-10-09': 'a', '2026-10-10': 'a'},
          from: CalendarDate(2026, 10, 8),
          to: CalendarDate(2026, 10, 11),
        );
        expect([for (final day in days) day.side], [a, a, a, b]);
        expect(
          [
            for (final day in days)
              if (day.isHandover) day.date,
          ],
          [CalendarDate(2026, 10, 11)],
        );
      },
    );

    test('an override this build cannot read is ignored, not guessed', () {
      final sides = custodySidesBetween(
        schedule: fixtureSchedule,
        overrides: const {'2026-10-09': 'c', 'not-a-date': 'a'},
        from: CalendarDate(2026, 10, 9),
        to: CalendarDate(2026, 10, 9),
      );
      expect(sides.values.single, b);
    });

    test('upcoming handovers are the next few, bounded by the horizon', () {
      final coming = upcomingHandovers(
        schedule: fixtureSchedule,
        overrides: const {},
        from: monday,
        count: 3,
      );
      expect(
        [for (final day in coming) day.date],
        [
          CalendarDate(2026, 10, 2),
          CalendarDate(2026, 10, 9),
          CalendarDate(2026, 10, 16),
        ],
      );
      final never = CustodyPresets.fromCycle(
        pattern: CustodyPattern.custom,
        startsOn: monday,
        days: List.filled(14, a),
      );
      expect(
        upcomingHandovers(schedule: never, overrides: const {}, from: monday),
        isEmpty,
      );
    });

    test('a window that ends before it starts has no days', () {
      expect(
        custodySidesBetween(
          schedule: fixtureSchedule,
          overrides: const {},
          from: monday.addDays(3),
          to: monday,
        ),
        isEmpty,
      );
    });
  });

  test('a side reads back from its stored name, and nothing else', () {
    expect(CustodySide.fromName('a'), a);
    expect(CustodySide.fromName('b'), b);
    expect(CustodySide.fromName('c'), isNull);
    expect(CustodySide.fromName(null), isNull);
    expect(a.other, b);
  });
}
