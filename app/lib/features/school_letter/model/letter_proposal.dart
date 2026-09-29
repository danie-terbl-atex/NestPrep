import 'package:flutter/foundation.dart';

import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';

/// One event a school letter proposed, on the household's wall clock
/// (calendar ADR-0002) — what the review list shows and what is saved, as an
/// ordinary event, only once the parent confirms it (calendar ADR-0005).
@immutable
final class LetterProposal {
  const LetterProposal({
    required this.title,
    required this.date,
    this.startMinute,
    this.endMinute,
    this.recurrence,
    this.memberIds = const [],
    this.note,
  });

  final String title;
  final CalendarDate date;

  /// Null on both means all day.
  final int? startMinute;
  final int? endMinute;
  final RecurrenceRule? recurrence;
  final List<String> memberIds;

  /// What to bring or do, from the letter.
  final String? note;

  bool get isAllDay => startMinute == null;

  /// One proposal from the callable's reply, parsed and never cast
  /// (`ENG-09`); null for anything that is not one, which the list then
  /// leaves out rather than guessing at.
  static LetterProposal? fromWire(Object? value) {
    if (value is! Map) return null;
    final title = value['title'];
    final date = _day(value['date']);
    if (title is! String || title.trim().isEmpty || date == null) return null;
    final start = _minute(value['startMinute']);
    return LetterProposal(
      title: title.trim(),
      date: date,
      startMinute: start,
      endMinute: start == null ? null : _minute(value['endMinute']),
      recurrence: _rule(value['recurrence']),
      memberIds: [
        if (value['memberIds'] case final List<Object?> ids)
          for (final id in ids)
            if (id is String && id.isNotEmpty) id,
      ],
      note: switch (value['note']) {
        final String note when note.trim().isNotEmpty => note.trim(),
        _ => null,
      },
    );
  }

  static CalendarDate? _day(Object? value) {
    if (value is! String) return null;
    try {
      return CalendarDate.parse(value);
    } on FormatException {
      return null;
    }
  }

  static int? _minute(Object? value) =>
      value is int && value >= 0 && value < 24 * 60 ? value : null;

  static RecurrenceRule? _rule(Object? value) {
    if (value is! Map) return null;
    final frequency = RecurrenceFrequency.values
        .where((candidate) => candidate.name == value['frequency'])
        .firstOrNull;
    if (frequency == null) return null;
    final rule = RecurrenceRule(
      frequency: frequency,
      interval: switch (value['interval']) {
        final int interval => interval,
        _ => 1,
      },
      weekdays: [
        if (value['weekdays'] case final List<Object?> days)
          for (final day in days)
            if (day is int) day,
      ],
      until: _day(value['until']),
    );
    return rule.isExpandable ? rule : null;
  }

  @override
  bool operator ==(Object other) =>
      other is LetterProposal &&
      other.title == title &&
      other.date == date &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.recurrence == recurrence &&
      listEquals(other.memberIds, memberIds) &&
      other.note == note;

  @override
  int get hashCode => Object.hash(
    title,
    date,
    startMinute,
    endMinute,
    recurrence,
    Object.hashAll(memberIds),
    note,
  );
}
