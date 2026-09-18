import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/birthday_converter.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// The rules a birthday keeps, all of which a wrong answer would show a
/// household on the wrong day (birthdays ADR-0001).
void main() {
  group('the two stored shapes', () {
    test('a birthday with a year is a date', () {
      final birthday = Birthday(year: 1985, month: 12, day: 10);
      expect(birthday.iso, '1985-12-10');
      expect(birthday.hasYear, isTrue);
      expect(Birthday.parse('1985-12-10'), birthday);
    });

    test('a birthday without one is a day and a month, and says so', () {
      final birthday = Birthday(month: 7, day: 4);
      expect(birthday.iso, '--07-04');
      expect(birthday.hasYear, isFalse);
      expect(Birthday.parse('--07-04'), birthday);
    });

    test('the two are not the same birthday', () {
      expect(
        Birthday(year: 1985, month: 12, day: 10) ==
            Birthday(month: 12, day: 10),
        isFalse,
        reason: 'one of them knows something the other does not',
      );
    });

    test('a value that is not a birthday is refused, never guessed at', () {
      for (final wrong in [
        '',
        '10-12',
        '1985/12/10',
        '--13-01',
        '1985-02-31',
      ]) {
        expect(
          () => Birthday.parse(wrong),
          throwsA(isA<FormatException>()),
          reason: '$wrong is not a birthday',
        );
      }
    });

    test('29 February is a birthday even with no year to be leap', () {
      expect(Birthday(month: 2, day: 29).iso, '--02-29');
      expect(
        () => Birthday(year: 2025, month: 2, day: 29),
        throwsA(isA<FormatException>()),
        reason: '2025 has no 29 February, so nobody was born on it',
      );
    });
  });

  group('the day it falls on', () {
    test('is the same day of the same month, year after year', () {
      final birthday = Birthday(year: 2018, month: 6, day: 5);
      expect(birthday.occurrenceIn(2026).iso, '2026-06-05');
      expect(birthday.occurrenceIn(2027).iso, '2027-06-05');
    });

    test('29 February is kept on the 28th in a year that has no 29th', () {
      final birthday = Birthday(year: 2016, month: 2, day: 29);
      expect(birthday.occurrenceIn(2024).iso, '2024-02-29');
      expect(
        birthday.occurrenceIn(2026).iso,
        '2026-02-28',
        reason:
            'it is a February birthday; 1 March would put it in the wrong '
            'month on the week strip and in the wrong month when somebody '
            'says which month it is in',
      );
    });
  });

  group('the age', () {
    test('is the age turned that year', () {
      expect(Birthday(year: 1985, month: 12, day: 10).ageTurningIn(2026), 41);
    });

    test('is unknown when the year is', () {
      expect(Birthday(month: 12, day: 10).ageTurningIn(2026), isNull);
    });

    test('is unknown rather than negative for a year in the future', () {
      // No picker allows it; a document written elsewhere still could.
      expect(
        Birthday(year: 2030, month: 1, day: 1).ageTurningIn(2026),
        isNull,
        reason: '"turns -4" is worse than saying nothing',
      );
    });

    test('a leap-day birthday still turns its age on the 28th', () {
      final birthday = Birthday(year: 2016, month: 2, day: 29);
      expect(birthday.occurrenceIn(2026).iso, '2026-02-28');
      expect(birthday.ageTurningIn(2026), 10);
    });
  });

  group('crossing the Firestore boundary', () {
    const converter = BirthdayConverter();

    test('a member written before the field existed still reads', () {
      final member = Member.fromJson(const {
        'id': 'm1',
        'displayName': 'Ada',
        'color': 'teal',
        'role': 'admin',
      });
      expect(member.birthday, isNull);
      expect(member.displayName, 'Ada');
    });

    test('an unreadable birthday reads as none, not as a broken household', () {
      // Every screen in the app waits on the member listener, so one bad field
      // on one profile must not take the whole household down (`BE-10`).
      expect(converter.fromJson('not-a-birthday'), isNull);
      expect(converter.fromJson(19851210), isNull);
      expect(converter.fromJson(null), isNull);
    });

    test('and one that is readable round-trips both ways', () {
      for (final iso in ['1985-12-10', '--02-29']) {
        expect(converter.toJson(converter.fromJson(iso)), iso);
      }
    });

    test('a birthday reaches the model through the member converter', () {
      final member = Member.fromJson(const {
        'id': 'm1',
        'displayName': 'Ada',
        'color': 'teal',
        'role': 'admin',
        'birthday': '--02-29',
      });
      expect(member.birthday, Birthday(month: 2, day: 29));
      expect(member.color, MemberColor.teal);
    });
  });

  test('a day becomes the birthday on it, year and all', () {
    expect(
      Birthday.on(CalendarDate.parse('2026-09-18')),
      Birthday(year: 2026, month: 9, day: 18),
    );
  });

  test('a list of them reads as a calendar, not as an arrival order', () {
    final byDayOfYear = [
      Birthday(month: 12, day: 10),
      Birthday(year: 1990, month: 1, day: 4),
      Birthday(month: 1, day: 2),
    ]..sort();
    expect(byDayOfYear.map((b) => b.iso), ['--01-02', '1990-01-04', '--12-10']);
  });
}
