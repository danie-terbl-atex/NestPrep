import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/quick_add/quick_add_result.dart';

import '../../../support/quick_add_harness.dart';

/// Repeats: a plural weekday is weekly, and so is a list of weekdays; ends are
/// a day, a month (through its last day), a span or a count (calendar
/// ADR-0004, foundation ADR-0005). Today is Tuesday 29 September 2026.
void main() {
  group('weekly', () {
    test('two plural weekdays are one rule on both', () {
      expectProposal(
        'Piano Tuesdays and Thursdays 3-4pm',
        title: 'Piano',
        on: '2026-09-29',
        start: at(15),
        end: at(16),
        repeats: weekly([2, 4]),
      );
    });

    test(
      'a list of short weekdays is weekly, starting on the first to come',
      () {
        expectProposal(
          'Gym Mon, Wed and Fri 6am',
          title: 'Gym',
          on: '2026-09-30',
          start: at(6),
          end: at(7),
          repeats: weekly([1, 3, 5]),
        );
      },
    );

    test('"weekdays" is Monday to Friday', () {
      expectProposal(
        'School run weekdays at 7:30',
        title: 'School run',
        on: '2026-09-29',
        start: at(7, 30),
        end: at(8, 30),
        repeats: weekly([1, 2, 3, 4, 5]),
      );
      expectProposal(
        'Standup every weekday 09:00',
        title: 'Standup',
        on: '2026-09-29',
        start: at(9),
        end: at(10),
        repeats: weekly([1, 2, 3, 4, 5]),
      );
    });

    test('"weekends" is Saturday and Sunday', () {
      expectProposal(
        'Lie in on weekends',
        title: 'Lie in',
        on: '2026-10-03',
        repeats: weekly([6, 7]),
      );
    });

    test('"every Tuesday" and "every week on Sunday"', () {
      expectProposal(
        "Chess club every Tuesday 5 o'clock",
        title: 'Chess club',
        on: '2026-09-29',
        start: at(17),
        end: at(18),
        repeats: weekly([2]),
      );
      expectProposal(
        'Rubbish out every week on Sunday',
        title: 'Rubbish out',
        on: '2026-10-04',
        repeats: weekly([7]),
      );
    });

    test('"fortnightly on Thursday" and "every second Thursday" match', () {
      final expected = weekly([4], every: 2);
      expectProposal(
        'Swimming fortnightly on Thursday at 4',
        title: 'Swimming',
        on: '2026-10-01',
        start: at(16),
        end: at(17),
        repeats: expected,
      );
      expectProposal(
        'Swimming every second Thursday at 4',
        title: 'Swimming',
        on: '2026-10-01',
        start: at(16),
        end: at(17),
        repeats: expected,
      );
    });

    test('a repeat starts from the day it was given', () {
      expectProposal(
        'Ballet Saturdays from 17 October at 9',
        title: 'Ballet',
        on: '2026-10-17',
        start: at(9),
        end: at(10),
        repeats: weekly([6]),
      );
    });
  });

  group('daily, monthly, yearly', () {
    test('"every 3 days" and "daily"', () {
      expectProposal(
        'Water plants every 3 days',
        title: 'Water plants',
        on: '2026-09-29',
        repeats: daily(every: 3),
      );
      expectProposal(
        'Yoga daily at 6:30am until 15 October',
        title: 'Yoga',
        on: '2026-09-29',
        start: at(6, 30),
        end: at(7, 30),
        repeats: daily(until: '2026-10-15'),
      );
    });

    test('"monthly on the 1st" and "every month"', () {
      expectProposal(
        'Rent monthly on the 1st',
        title: 'Rent',
        on: '2026-10-01',
        repeats: monthly(),
      );
      expectProposal(
        'School fees every month',
        title: 'School fees',
        on: '2026-09-29',
        repeats: monthly(),
      );
    });

    test('"yearly" is every twelve months, the only year the rule knows', () {
      expectProposal(
        'Checkup yearly 3 March',
        title: 'Checkup',
        on: '2027-03-03',
        repeats: monthly(every: 12),
      );
    });
  });

  group('ends', () {
    test('"until 1 December" is that day', () {
      expectProposal(
        'Swimming every other Thursday 4pm until 1 December',
        title: 'Swimming',
        on: '2026-10-01',
        start: at(16),
        end: at(17),
        repeats: weekly([4], every: 2, until: '2026-12-01'),
      );
    });

    test('"until March" said in September is next March, through its end', () {
      expectProposal(
        'Netball Wednesdays until March',
        title: 'Netball',
        on: '2026-09-30',
        repeats: weekly([3], until: '2027-03-31'),
      );
    });

    test('"for 6 weeks" is six weeks from the first day', () {
      expectProposal(
        'Tennis Saturdays 9-10:30 for 6 weeks',
        title: 'Tennis',
        on: '2026-10-03',
        start: at(9),
        end: at(10, 30),
        repeats: weekly([6], until: '2026-11-13'),
      );
    });

    test('"10 times" ends on the tenth', () {
      expectProposal(
        'Rugby Saturdays 10 times',
        title: 'Rugby',
        on: '2026-10-03',
        repeats: weekly([6], until: '2026-12-05'),
      );
    });

    test('"for 3 months" ends the day before the same date', () {
      expectProposal(
        'Physio every week on Monday for 3 months',
        title: 'Physio',
        on: '2026-10-05',
        repeats: weekly([1], until: '2027-01-04'),
      );
    });
  });

  group('what it refuses', () {
    test('nothing typed', () {
      expectRefusal('', QuickAddProblem.empty);
      expectRefusal('   ', QuickAddProblem.empty);
    });

    test('no title once the rest is read', () {
      expectRefusal('at 5', QuickAddProblem.noTitle);
      expectRefusal('Tomorrow at 5pm', QuickAddProblem.noTitle);
      expectRefusal('Tuesdays', QuickAddProblem.noTitle);
    });

    test('nothing that says when', () {
      expectRefusal('Soccer', QuickAddProblem.noWhen);
      expectRefusal('Buy a present for Mia', QuickAddProblem.noWhen);
    });

    test('a day that is not in the calendar', () {
      expectRefusal('Dentist 31 February', QuickAddProblem.impossibleDate);
      expectRefusal('Dentist 30/2', QuickAddProblem.impossibleDate);
      expectRefusal('Dentist 2026-13-01', QuickAddProblem.impossibleDate);
      expectRefusal(
        'Swimming Thursdays until 31 June',
        QuickAddProblem.impossibleDate,
      );
    });

    test('a time that is not on a clock', () {
      expectRefusal('Dentist at 25:00', QuickAddProblem.impossibleTime);
      expectRefusal('Soccer at 13pm', QuickAddProblem.impossibleTime);
      expectRefusal('Meet 7:75', QuickAddProblem.impossibleTime);
    });

    test('a repeat that ends before it starts', () {
      expectRefusal(
        'Soccer Tuesdays until 1 September 2026',
        QuickAddProblem.endsBeforeStart,
      );
    });
  });
}
