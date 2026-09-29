import 'package:flutter_test/flutter_test.dart';

import '../../../support/quick_add_harness.dart';

/// Days and times as South African English writes them (calendar ADR-0004):
/// day before month, the 24-hour clock, `17h30`, and a bare hour read the way
/// a family calendar reads it. Today is Tuesday 29 September 2026.
void main() {
  group('days', () {
    final cases = <(String, String, String)>[
      ('Braai today', 'Braai', '2026-09-29'),
      ('Movie tonight', 'Movie', '2026-09-29'),
      ('Dinner tomorrow', 'Dinner', '2026-09-30'),
      ('Cake the day after tomorrow', 'Cake', '2026-10-01'),
      ('Braai Friday', 'Braai', '2026-10-02'),
      ('Braai this Friday', 'Braai', '2026-10-02'),
      ('Braai on Fri', 'Braai', '2026-10-02'),
      ('Book club next Friday', 'Book club', '2026-10-09'),
      ('Sports day Tuesday', 'Sports day', '2026-09-29'),
      ('Visit in 3 days', 'Visit', '2026-10-02'),
      ('Visit in two weeks', 'Visit', '2026-10-13'),
      ('Holiday club 12/10', 'Holiday club', '2026-10-12'),
      ('Holiday club 12/10/2026', 'Holiday club', '2026-10-12'),
      ('Holiday club 12-10-26', 'Holiday club', '2026-10-12'),
      ('Holiday club 12.10.2026', 'Holiday club', '2026-10-12'),
      ('Flight 2026-10-05', 'Flight', '2026-10-05'),
      ('Market 3 Oct', 'Market', '2026-10-03'),
      ('Market 3rd of October', 'Market', '2026-10-03'),
      ('Market October 3rd', 'Market', '2026-10-03'),
      ('Market Oct 3 2027', 'Market', '2027-10-03'),
      ('Market 3 Oct 2027', 'Market', '2027-10-03'),
      ('Dentist 3 March', 'Dentist', '2027-03-03'),
      ('Rent on the 1st', 'Rent', '2026-10-01'),
      ('Rent the 30th', 'Rent', '2026-09-30'),
      ('Leap day 29 Feb 2028', 'Leap day', '2028-02-29'),
    ];
    for (final (text, title, iso) in cases) {
      test('"$text" is $iso, all day', () {
        expectProposal(text, title: title, on: iso);
      });
    }

    test('"3/4" is the 3rd of April, never March the 4th', () {
      expectProposal('Fete 3/4', title: 'Fete', on: '2027-04-03');
    });

    test('"the 31st" skips a month that has no 31st', () {
      expectProposal(
        'Pay day the 31st',
        today: day('2026-09-15'),
        title: 'Pay day',
        on: '2026-10-31',
      );
    });

    test('"all day" says so and claims its words', () {
      expectProposal(
        'Holiday all day 16 December',
        title: 'Holiday',
        on: '2026-12-16',
      );
    });
  });

  group('times', () {
    final cases = <String, (int, int)>{
      'Call at 5': (at(17), at(18)),
      'Call at 7': (at(7), at(8)),
      'Call at 12': (at(12), at(13)),
      'Call at 5pm': (at(17), at(18)),
      'Call 5 pm': (at(17), at(18)),
      'Call 5am': (at(5), at(6)),
      'Call 5 a.m.': (at(5), at(6)),
      'Call 5:30pm': (at(17, 30), at(18, 30)),
      'Call 5.30pm': (at(17, 30), at(18, 30)),
      'Call 17:30': (at(17, 30), at(18, 30)),
      'Call 07:30': (at(7, 30), at(8, 30)),
      'Call 17h30': (at(17, 30), at(18, 30)),
      'Call 7h30': (at(7, 30), at(8, 30)),
      'Call 17h': (at(17), at(18)),
      'Call at noon': (at(12), at(13)),
      'Call at midday': (at(12), at(13)),
      'Call at midnight': (at(0), at(1)),
      'Call at half past 5': (at(17, 30), at(18, 30)),
      'Call quarter to 8': (at(7, 45), at(8, 45)),
      'Call quarter past three pm': (at(15, 15), at(16, 15)),
      'Call at five': (at(17), at(18)),
      "Call at 5 o'clock": (at(17), at(18)),
      'Call at 7 in the evening': (at(19), at(20)),
      'Call at 5 in the morning': (at(5), at(6)),
      'Call tonight at 8': (at(20), at(21)),
      'Call 3-5pm': (at(15), at(17)),
      'Call 11-1pm': (at(11), at(13)),
      'Call 3pm-4:30pm': (at(15), at(16, 30)),
      'Call 3-5 pm': (at(15), at(17)),
      'Call from 3 to 5': (at(15), at(17)),
      'Call from 8 to 12': (at(8), at(12)),
      'Call 10:30 to 12': (at(10, 30), at(12)),
      'Call 10pm-1am': (at(22), at(1)),
      'Call at 3pm for 2 hours': (at(15), at(17)),
      'Call at 10 for 45 min': (at(10), at(10, 45)),
      'Call at 10 for half an hour': (at(10), at(10, 30)),
      'Call at 9 for an hour': (at(9), at(10)),
    };
    for (final MapEntry(key: text, value: (start, end)) in cases.entries) {
      test(
        '"$text" is ${start ~/ 60}:${start % 60} to ${end ~/ 60}:${end % 60}',
        () {
          expectProposal(
            text,
            title: 'Call',
            on: '2026-09-29',
            start: start,
            end: end,
          );
        },
      );
    }

    test('a number before a month is a day, not a time', () {
      expectProposal('Fete from 3 March', title: 'Fete', on: '2027-03-03');
    });

    test('a bare number with nothing saying it is a time stays a word', () {
      expectProposal(
        'Grade 5 play Friday',
        title: 'Grade 5 play',
        on: '2026-10-02',
      );
    });
  });
}
