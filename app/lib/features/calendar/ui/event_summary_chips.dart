import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/quick_add_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';

/// An event that is not saved yet, read back as chips — the day, the time,
/// the repeat, who it is for — the way the week will show it. Quick add's
/// preview and a school letter's review list both say "this is what will be
/// added" with it (calendar ADR-0004, ADR-0005), so it is one widget
/// (`ENG-02`).
class EventSummaryChips extends StatelessWidget {
  const EventSummaryChips({
    required this.date,
    required this.today,
    required this.members,
    this.startMinute,
    this.endMinute,
    this.recurrence,
    super.key,
  });

  final CalendarDate date;
  final CalendarDate today;
  final int? startMinute;
  final int? endMinute;
  final RecurrenceRule? recurrence;

  /// The members it is for, already looked up.
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final rule = recurrence;
    final until = rule?.until;
    return Wrap(
      spacing: NestSpace.xs,
      runSpacing: NestSpace.xs,
      children: [
        NestChip(
          icon: Icons.event_outlined,
          label: NestDates.relative(date, today),
        ),
        NestChip(icon: Icons.schedule, label: _when()),
        if (rule != null)
          NestChip(
            icon: Icons.repeat,
            label: until == null
                ? QuickAddCopy.repeats(rule)
                : '${QuickAddCopy.repeats(rule)} '
                      '${QuickAddCopy.until(NestDates.full(until, today))}',
          ),
        for (final member in members)
          NestChip(icon: Icons.person_outline, label: member.displayName),
      ],
    );
  }

  String _when() {
    final start = startMinute;
    if (start == null) return AppCopy.calendarAllDay;
    final end = endMinute;
    final from = NestDates.timeOfDay(start);
    return end == null ? from : '$from – ${NestDates.timeOfDay(end)}';
  }
}
