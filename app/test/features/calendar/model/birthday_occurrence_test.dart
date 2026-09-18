import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/calendar/model/birthday_occurrence.dart';
import 'package:nestprep/features/calendar/model/calendar_week.dart';
import 'package:nestprep/features/calendar/model/day_entry.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/household_fixtures.dart';

CalendarDate date(String iso) => CalendarDate.parse(iso);

Member member({
  required String id,
  required String name,
  Birthday? birthday,
  MemberColor color = MemberColor.violet,
}) => Member(
  id: id,
  displayName: name,
  color: color,
  roleName: 'member',
  birthday: birthday,
);

/// Deriving the birthdays a window shows, which is the whole of what the
/// calendar stores about them: nothing (birthdays ADR-0001).
void main() {
  test('a member with no birthday puts nothing on any day', () {
    expect(
      selectBirthdayOccurrences(
        members: [member(id: 'm1', name: 'Ada')],
        from: date('2026-09-14'),
        to: date('2026-09-20'),
      ),
      isEmpty,
    );
  });

  test('a birthday inside the window lands on its day, with the age', () {
    final occurrences = selectBirthdayOccurrences(
      members: [
        member(
          id: 'm1',
          name: 'Ada',
          birthday: Birthday(year: 1985, month: 9, day: 18),
        ),
      ],
      from: date('2026-09-14'),
      to: date('2026-09-20'),
    );

    expect(occurrences.single.date.iso, '2026-09-18');
    expect(occurrences.single.age, 41);
    expect(occurrences.single.member.displayName, 'Ada');
  });

  test('a birthday outside it lands nowhere', () {
    expect(
      selectBirthdayOccurrences(
        members: [
          member(
            id: 'm1',
            name: 'Ada',
            birthday: Birthday(year: 1985, month: 9, day: 21),
          ),
        ],
        from: date('2026-09-14'),
        to: date('2026-09-20'),
      ),
      isEmpty,
    );
  });

  test('the year is unknown, so the age is too', () {
    final occurrences = selectBirthdayOccurrences(
      members: [
        member(id: 'm1', name: 'Ada', birthday: Birthday(month: 9, day: 18)),
      ],
      from: date('2026-09-14'),
      to: date('2026-09-20'),
    );
    expect(occurrences.single.age, isNull);
  });

  test('a week across new year covers both years', () {
    final occurrences = selectBirthdayOccurrences(
      members: [
        member(
          id: 'm1',
          name: 'Ada',
          birthday: Birthday(year: 1985, month: 12, day: 31),
        ),
        member(
          id: 'm2',
          name: 'Ben',
          birthday: Birthday(year: 2019, month: 1, day: 2),
        ),
      ],
      from: date('2026-12-28'),
      to: date('2027-01-03'),
    );

    expect(occurrences.map((o) => o.date.iso), ['2026-12-31', '2027-01-02']);
    expect(occurrences.map((o) => o.age), [41, 8]);
  });

  test('29 February is derived onto the 28th in a non-leap year', () {
    final leapling = member(
      id: 'm1',
      name: 'Ada',
      birthday: Birthday(year: 2016, month: 2, day: 29),
    );

    expect(
      selectBirthdayOccurrences(
        members: [leapling],
        from: date('2026-02-23'),
        to: date('2026-03-01'),
      ).single.date.iso,
      '2026-02-28',
    );
    expect(
      selectBirthdayOccurrences(
        members: [leapling],
        from: date('2024-02-26'),
        to: date('2024-03-03'),
      ).single.date.iso,
      '2024-02-29',
      reason: 'a leap year keeps the real day',
    );
  });

  test('two on one day read by name, not by the order they arrived', () {
    final occurrences = selectBirthdayOccurrences(
      members: [
        member(id: 'm2', name: 'Zoe', birthday: Birthday(month: 9, day: 18)),
        member(id: 'm1', name: 'Ada', birthday: Birthday(month: 9, day: 18)),
      ],
      from: date('2026-09-14'),
      to: date('2026-09-20'),
    );
    expect(occurrences.map((o) => o.member.displayName), ['Ada', 'Zoe']);
  });

  test('its key is its own, so a day holding both never reuses one', () {
    final birthday = selectBirthdayOccurrences(
      members: [
        member(id: 'm1', name: 'Ada', birthday: Birthday(month: 9, day: 18)),
      ],
      from: date('2026-09-14'),
      to: date('2026-09-20'),
    ).single;
    expect(birthday.key, 'birthday_m1_2026-09-18');
  });

  group('merged into the week', () {
    CalendarWeek weekOf({String? memberFilter}) => CalendarWeek.from(
      occurrences: const [],
      birthdays: selectBirthdayOccurrences(
        members: [
          member(
            id: Fixtures.kidMemberId,
            name: 'Kid Parker',
            birthday: Birthday(year: 2017, month: 9, day: 18),
          ),
          member(
            id: Fixtures.samMemberId,
            name: 'Sam Parent',
            birthday: Birthday(month: 9, day: 19),
          ),
        ],
        from: date('2026-09-14'),
        to: date('2026-09-20'),
      ),
      weekStart: date('2026-09-14'),
      today: date('2026-09-18'),
      memberFilter: memberFilter,
    );

    test('a day with only a birthday on it is not an empty day', () {
      final week = weekOf();
      expect(week.isEmpty, isFalse);
      expect(week.on(date('2026-09-18')), hasLength(1));
      expect(week.on(date('2026-09-17')), isEmpty);
    });

    test('it arrives as a birthday entry, which holds no event at all', () {
      final entry = weekOf().on(date('2026-09-18')).single;
      expect(entry, isA<BirthdayEntry>());
      expect(
        entry,
        isNot(isA<EventEntry>()),
        reason: 'there is no event behind it to edit, delete or skip',
      );
    });

    test('the member filter hides everybody else"s', () {
      final week = weekOf(memberFilter: Fixtures.kidMemberId);
      expect(week.on(date('2026-09-18')), hasLength(1));
      expect(
        week.on(date('2026-09-19')),
        isEmpty,
        reason: 'showing one member means one member',
      );
    });
  });
}
