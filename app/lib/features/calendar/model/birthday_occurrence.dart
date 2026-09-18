import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';

/// One member's birthday, on one day of one year.
///
/// Nothing stores this. It is derived from the member's profile every time a
/// window is shown, which is what makes renaming or recolouring a member change
/// the calendar for free and removing one leave nothing behind (birthdays
/// ADR-0001).
class BirthdayOccurrence {
  const BirthdayOccurrence({
    required this.member,
    required this.date,
    required this.age,
  });

  final Member member;
  final CalendarDate date;

  /// The age turned on this day, or null when the household does not know the
  /// year — in which case the row says whose birthday it is instead.
  final int? age;

  /// Stable across rebuilds, and distinct from an event's key, so a list that
  /// holds both never reuses one (`FE-11`).
  String get key => 'birthday_${member.id}_${date.iso}';
}

/// Every birthday that falls inside a window, in the order a day reads them.
///
/// Pure, and the only place a birthday becomes a day, so the week strip and the
/// agenda can never disagree about which day one is on.
List<BirthdayOccurrence> selectBirthdayOccurrences({
  required List<Member> members,
  required CalendarDate from,
  required CalendarDate to,
}) {
  final occurrences = <BirthdayOccurrence>[];
  // A window is a week, so it spans one year or two; both are covered without
  // expanding a lifetime of birthdays nobody asked for (`BE-08`).
  for (var year = from.year; year <= to.year; year++) {
    for (final member in members) {
      final birthday = member.birthday;
      if (birthday == null) continue;
      final date = birthday.occurrenceIn(year);
      if (!date.isInRange(from, to)) continue;
      occurrences.add(
        BirthdayOccurrence(
          member: member,
          date: date,
          age: birthday.ageTurningIn(year),
        ),
      );
    }
  }

  occurrences.sort(_byDayThenName);
  return occurrences;
}

int _byDayThenName(BirthdayOccurrence a, BirthdayOccurrence b) {
  final byDay = a.date.compareTo(b.date);
  if (byDay != 0) return byDay;
  final byName = a.member.displayName.toLowerCase().compareTo(
    b.member.displayName.toLowerCase(),
  );
  return byName != 0 ? byName : a.member.id.compareTo(b.member.id);
}
