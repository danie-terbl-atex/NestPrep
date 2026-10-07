import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/quick_add/quick_add_result.dart';
import 'package:nestprep/shared/recurrence/recurrence_expansion.dart';

import '../../../support/quick_add_harness.dart';

/// The three sentences the phase note names, and what makes the grammar
/// trustworthy: it reads no clock (calendar ADR-0004). Today is Tuesday
/// 29 September 2026 throughout.
void main() {
  group('the sentences the phase is judged on', () {
    test('"Soccer Tuesdays at 5" is weekly on Tuesday at 17:00', () {
      expectProposal(
        'Soccer Tuesdays at 5',
        title: 'Soccer',
        on: '2026-09-29',
        start: at(17),
        end: at(18),
        repeats: weekly([2]),
      );
    });

    test('"Dentist 3 March 10:30 for Mia" is next March, for Mia', () {
      expectProposal(
        'Dentist 3 March 10:30 for Mia',
        title: 'Dentist',
        on: '2027-03-03',
        start: at(10, 30),
        end: at(11, 30),
        members: ['m-mia'],
      );
    });

    test('"Swimming every other Thursday 4pm until December" is fortnightly '
        'through the end of December', () {
      expectProposal(
        'Swimming every other Thursday 4pm until December',
        title: 'Swimming',
        on: '2026-10-01',
        start: at(16),
        end: at(17),
        repeats: weekly([4], every: 2, until: '2026-12-31'),
      );
    });
  });

  group('a proposal is what the calendar will draw', () {
    test('the soccer rule lands on every Tuesday of October', () {
      final proposal = parse('Soccer Tuesdays at 5') as QuickAddProposal;
      final days = expandOccurrences(
        firstDate: proposal.date,
        rule: proposal.recurrence,
        windowStart: day('2026-10-01'),
        windowEnd: day('2026-10-31'),
      );
      expect(days.map((d) => d.iso), [
        '2026-10-06',
        '2026-10-13',
        '2026-10-20',
        '2026-10-27',
      ]);
    });

    test('the swimming rule skips the Thursdays in between', () {
      final proposal =
          parse('Swimming every other Thursday 4pm until December')
              as QuickAddProposal;
      final days = expandOccurrences(
        firstDate: proposal.date,
        rule: proposal.recurrence,
        windowStart: day('2026-10-01'),
        windowEnd: day('2027-01-31'),
      );
      expect(days.first.iso, '2026-10-01');
      expect(days.last.iso, '2026-12-24');
      expect(days, hasLength(7));
    });

    test('a repeat keeps its wall-clock time, not an instant', () {
      // Nothing in a proposal is an instant, so there is nothing for a clocks
      // change to move: 17:00 is stored as 17:00 (calendar ADR-0002).
      final proposal = parse('Soccer Tuesdays at 5') as QuickAddProposal;
      expect(proposal.startMinute, at(17));
      expect(proposal.isAllDay, isFalse);
    });
  });

  group('it reads no clock', () {
    test('the same sentence on the same day is the same proposal', () {
      expect(parse('Soccer Tuesdays at 5'), parse('Soccer Tuesdays at 5'));
    });

    test('said on a Wednesday, "Tuesdays" starts next Tuesday', () {
      expectProposal(
        'Soccer Tuesdays at 5',
        today: day('2026-09-30'),
        title: 'Soccer',
        on: '2026-10-06',
        start: at(17),
        end: at(18),
        repeats: weekly([2]),
      );
    });

    test('"3 March" said on 2 March is this year', () {
      expectProposal(
        'Dentist 3 March',
        today: day('2027-03-02'),
        title: 'Dentist',
        on: '2027-03-03',
      );
    });
  });

  group('members', () {
    test('"for Mia and Sam" is for both, by first name', () {
      expectProposal(
        'Soccer Tuesdays at 5 for Mia and Sam',
        title: 'Soccer',
        on: '2026-09-29',
        start: at(17),
        end: at(18),
        repeats: weekly([2]),
        members: ['m-mia', 'm-sam'],
      );
    });

    test('a full name matches too, whatever its case', () {
      expectProposal(
        'Haircut friday 3pm for sam parker',
        title: 'Haircut',
        on: '2026-10-02',
        start: at(15),
        end: at(16),
        members: ['m-sam'],
      );
    });

    test('"with Thandi" and "Mia\'s" both name a member', () {
      expectProposal(
        'Lunch with Thandi at noon',
        title: 'Lunch',
        on: '2026-09-29',
        start: at(12),
        end: at(13),
        members: ['m-thandi'],
      );
      expectProposal(
        "Mia's party 3 Oct 2pm-5pm",
        title: 'Party',
        on: '2026-10-03',
        start: at(14),
        end: at(17),
        members: ['m-mia'],
      );
    });

    test('a name that is not a member stays in the title', () {
      expectProposal(
        'Present for Gran Friday',
        title: 'Present for Gran',
        on: '2026-10-02',
      );
    });
  });

  group('titles', () {
    test('keep what was typed, capitalised, without the joining words', () {
      expectProposal(
        'parents evening on Thursday at 18h30',
        title: 'Parents evening',
        on: '2026-10-01',
        start: at(18, 30),
        end: at(19, 30),
      );
      expectProposal(
        'Soccer at school Tuesdays at 5',
        title: 'Soccer at school',
        on: '2026-09-29',
        start: at(17),
        end: at(18),
        repeats: weekly([2]),
      );
    });

    test('shouting and punctuation are read through', () {
      expectProposal(
        'SOCCER, Tuesdays @ 5!',
        title: 'SOCCER',
        on: '2026-09-29',
        start: at(17),
        end: at(18),
        repeats: weekly([2]),
      );
    });

    test('"Morning run" keeps its name and still means the morning', () {
      expectProposal(
        'Morning run Mondays at 6',
        title: 'Morning run',
        on: '2026-10-05',
        start: at(6),
        end: at(7),
        repeats: weekly([1]),
      );
    });
  });
}
