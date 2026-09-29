import '../../../../shared/recurrence/recurrence_expansion.dart';
import '../../../../shared/recurrence/recurrence_rule.dart';
import '../../../../shared/time/calendar_date.dart';
import 'date_phrase_reader.dart';
import 'member_phrase_reader.dart';
import 'quick_add_result.dart';
import 'quick_add_sentence.dart';
import 'repeat_phrase_reader.dart';
import 'time_phrase_reader.dart';

/// Turns one line — "Soccer Tuesdays at 5", "Dentist 3 March 10:30 for Mia" —
/// into an event to propose, or a reason it cannot (calendar ADR-0004).
///
/// Pure: [today] is the household's today (from `HouseholdClock`) and
/// [members] are the household's profiles, both handed in, so a sentence on a
/// day always reads the same and every case is a test.
///
/// The readers run in an order that matters. Repeats go first, because
/// "Tuesdays" is a habit and not a day, and "until December" is an end and not
/// a date. Times go before dates, so "tonight" is heard as the evening before
/// it is claimed as today. Names go last, after "for 2 hours" and "for 6
/// weeks" have been taken. What is left is the title.
QuickAddResult parseQuickAdd(
  String text, {
  required CalendarDate today,
  List<QuickAddMember> members = const [],
}) {
  if (text.trim().isEmpty) return const QuickAddRefusal(QuickAddProblem.empty);

  final sentence = QuickAddSentence(text);
  final dates = DatePhraseReader(sentence, today: today);
  final repeat = RepeatPhraseReader(sentence, dates: dates).read();
  final time = TimePhraseReader(sentence).read();
  final date = dates.read();
  final memberIds = MemberPhraseReader(sentence, members).read();

  if (time.isImpossible) {
    return const QuickAddRefusal(QuickAddProblem.impossibleTime);
  }
  if (date.isImpossible || (repeat?.isImpossible ?? false)) {
    return const QuickAddRefusal(QuickAddProblem.impossibleDate);
  }
  if (repeat == null && date.date == null && !time.saidSomething) {
    return const QuickAddRefusal(QuickAddProblem.noWhen);
  }
  final title = sentence.leftover;
  if (title.isEmpty) return const QuickAddRefusal(QuickAddProblem.noTitle);

  final firstDate = _firstDate(repeat, from: date.date ?? today);
  final rule = repeat == null ? null : _ruleFor(repeat, firstDate);
  final until = rule?.until;
  if (until != null && until.isBefore(firstDate)) {
    return const QuickAddRefusal(QuickAddProblem.endsBeforeStart);
  }

  return QuickAddProposal(
    title: title,
    date: firstDate,
    startMinute: time.startMinute,
    endMinute: time.endMinute,
    recurrence: rule,
    memberIds: memberIds,
  );
}

/// A weekly repeat on chosen weekdays starts on the first of them on or after
/// the day it was given — "Tuesdays" said on a Wednesday starts next Tuesday.
CalendarDate _firstDate(RepeatOfEvent? repeat, {required CalendarDate from}) {
  if (repeat == null ||
      repeat.frequency != RecurrenceFrequency.weekly ||
      repeat.weekdays.isEmpty) {
    return from;
  }
  final candidates = [
    for (final weekday in repeat.weekdays)
      DatePhraseReader.nextOnOrAfter(from, weekday),
  ]..sort();
  return candidates.first;
}

RecurrenceRule _ruleFor(RepeatOfEvent repeat, CalendarDate firstDate) {
  final open = RecurrenceRule(
    frequency: repeat.frequency,
    interval: repeat.interval,
    weekdays: repeat.weekdays,
  );
  final end = repeat.end;
  return switch (end) {
    null => open,
    EndsOn(:final date) => open.copyWith(until: date),
    EndsAfterSpan() => open.copyWith(until: _spanEnd(firstDate, end)),
    EndsAfterCount(:final count) => open.copyWith(
      until: _countEnd(firstDate, open, count),
    ),
  };
}

/// "for 6 weeks" from a Tuesday ends on the Monday six weeks on — the span is
/// the six weeks, whatever the interval inside it.
CalendarDate _spanEnd(CalendarDate firstDate, EndsAfterSpan span) {
  if (!RepeatPhraseReader.isMonthUnit(span.unitDays)) {
    return firstDate.addDays((span.amount * span.unitDays) - 1);
  }
  final total = (firstDate.year * 12) + (firstDate.month - 1) + span.amount;
  final year = total ~/ 12;
  final month = (total % 12) + 1;
  final day = firstDate.day.clamp(1, CalendarDate.daysIn(year, month));
  return CalendarDate(year, month, day).addDays(-1);
}

/// "10 times" ends on the tenth occurrence, found by the same expansion the
/// calendar draws with, so the preview and the week can never disagree.
CalendarDate _countEnd(CalendarDate firstDate, RecurrenceRule rule, int count) {
  final daysPerStep = switch (rule.frequency) {
    RecurrenceFrequency.daily => 1,
    RecurrenceFrequency.weekly => 7,
    RecurrenceFrequency.monthly => 31,
  };
  final occurrences = expandOccurrences(
    firstDate: firstDate,
    rule: rule,
    windowStart: firstDate,
    windowEnd: firstDate.addDays((count * rule.interval * daysPerStep) + 62),
  );
  return occurrences.length >= count
      ? occurrences[count - 1]
      : occurrences.last;
}
