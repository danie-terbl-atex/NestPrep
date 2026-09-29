import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/quick_add/quick_add_parser.dart';
import 'package:nestprep/features/calendar/model/quick_add/quick_add_result.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Tuesday 29 September 2026 — the "today" every quick-add case reads from,
/// handed in, never the clock (calendar ADR-0004).
final quickAddToday = CalendarDate(2026, 9, 29);

const mia = QuickAddMember(id: 'm-mia', name: 'Mia');
const sam = QuickAddMember(id: 'm-sam', name: 'Sam Parker');
const thandi = QuickAddMember(id: 'm-thandi', name: 'Thandi');
const household = [mia, sam, thandi];

CalendarDate day(String iso) => CalendarDate.parse(iso);

int at(int hour, [int minute = 0]) => (hour * 60) + minute;

QuickAddResult parse(String text, {CalendarDate? today}) =>
    parseQuickAdd(text, today: today ?? quickAddToday, members: household);

/// Parses [text] and checks it became exactly this proposal.
void expectProposal(
  String text, {
  required String title,
  required String on,
  int? start,
  int? end,
  RecurrenceRule? repeats,
  List<String> members = const [],
  CalendarDate? today,
}) {
  expect(
    parse(text, today: today),
    QuickAddProposal(
      title: title,
      date: day(on),
      startMinute: start,
      endMinute: end,
      recurrence: repeats,
      memberIds: members,
    ),
    reason: '"$text"',
  );
}

void expectRefusal(String text, QuickAddProblem problem) {
  expect(parse(text), QuickAddRefusal(problem), reason: '"$text"');
}

RecurrenceRule weekly(List<int> weekdays, {int every = 1, String? until}) =>
    RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: every,
      weekdays: weekdays,
      until: until == null ? null : day(until),
    );

RecurrenceRule daily({int every = 1, String? until}) => RecurrenceRule(
  frequency: RecurrenceFrequency.daily,
  interval: every,
  until: until == null ? null : day(until),
);

RecurrenceRule monthly({int every = 1, String? until}) => RecurrenceRule(
  frequency: RecurrenceFrequency.monthly,
  interval: every,
  until: until == null ? null : day(until),
);
