import '../../../../shared/recurrence/recurrence_rule.dart';
import '../../../../shared/time/calendar_date.dart';

/// What one line of quick add became (calendar ADR-0004). Nothing here is
/// saved: a proposal is shown to the member, who adds it, edits it or keeps
/// typing.
sealed class QuickAddResult {
  const QuickAddResult();
}

/// An event the grammar understood, on the household's wall clock (calendar
/// ADR-0002) with a rule in the shared shape (foundation ADR-0005).
final class QuickAddProposal extends QuickAddResult {
  const QuickAddProposal({
    required this.title,
    required this.date,
    this.startMinute,
    this.endMinute,
    this.recurrence,
    this.memberIds = const [],
  });

  final String title;

  /// The first occurrence: for a repeat, the first day it lands on.
  final CalendarDate date;

  /// Null on both means all day.
  final int? startMinute;
  final int? endMinute;
  final RecurrenceRule? recurrence;
  final List<String> memberIds;

  bool get isAllDay => startMinute == null;

  @override
  bool operator ==(Object other) =>
      other is QuickAddProposal &&
      other.title == title &&
      other.date == date &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.recurrence == recurrence &&
      _sameIds(other.memberIds, memberIds);

  @override
  int get hashCode => Object.hash(
    title,
    date,
    startMinute,
    endMinute,
    recurrence,
    Object.hashAll(memberIds),
  );

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'QuickAddProposal($title, $date, $startMinute–$endMinute, '
      '$recurrence, $memberIds)';
}

/// Why a line could not become an event. Each is a sentence in the copy file,
/// never shown as a code (`FE-09`).
enum QuickAddProblem {
  /// Nothing typed.
  empty,

  /// Everything typed was a day, a time or a name — "at 5".
  noTitle,

  /// No day, time or repeat — "Soccer" on its own is a to-do.
  noWhen,

  /// A day that is not in the calendar — "31 February".
  impossibleDate,

  /// A time that is not on a clock — "25:00".
  impossibleTime,

  /// A repeat whose end is before its first day.
  endsBeforeStart,
}

final class QuickAddRefusal extends QuickAddResult {
  const QuickAddRefusal(this.problem);

  final QuickAddProblem problem;

  @override
  bool operator ==(Object other) =>
      other is QuickAddRefusal && other.problem == problem;

  @override
  int get hashCode => problem.hashCode;

  @override
  String toString() => 'QuickAddRefusal($problem)';
}

/// A member quick add can recognise by name.
final class QuickAddMember {
  const QuickAddMember({required this.id, required this.name});

  final String id;
  final String name;
}
