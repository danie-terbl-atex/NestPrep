import 'package:flutter/material.dart';

import '../../design/nest_kit.dart';
import '../copy/app_copy.dart';
import '../recurrence/recurrence_rule.dart';
import '../time/calendar_date.dart';

/// Builds the small subset of recurrence NestPrep supports (foundation
/// ADR-0005): never, daily, weekly on chosen weekdays, or monthly — with an
/// interval and an optional end date.
///
/// Shared by todos and the calendar, which is why it lives here rather than in
/// either (`ENG-02`). A change to it changes both features' idea of "repeats".
class RecurrenceEditor extends StatelessWidget {
  const RecurrenceEditor({
    required this.rule,
    required this.firstDate,
    required this.onChanged,
    super.key,
  });

  final RecurrenceRule? rule;

  /// The day the thing starts, which is what a weekly rule falls back to when
  /// no weekday has been chosen.
  final CalendarDate firstDate;

  final ValueChanged<RecurrenceRule?> onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final current = rule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCopy.repeatLabel,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestChip(
              label: AppCopy.repeatNever,
              isSelected: current == null,
              onTap: () => onChanged(null),
            ),
            for (final frequency in RecurrenceFrequency.values)
              NestChip(
                label: _frequencyLabel(frequency),
                isSelected: current?.frequency == frequency,
                onTap: () => onChanged(_ruleFor(frequency, current)),
              ),
          ],
        ),
        if (current != null &&
            current.frequency == RecurrenceFrequency.weekly) ...[
          const SizedBox(height: NestSpace.lg),
          Text(
            AppCopy.repeatOnDaysLabel,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          _WeekdayPicker(
            selected: current.weekdays.isEmpty
                ? [firstDate.weekday]
                : current.weekdays,
            onChanged: (weekdays) =>
                onChanged(current.copyWith(weekdays: weekdays)),
          ),
        ],
      ],
    );
  }

  /// Keeps the interval and end date when somebody changes their mind about the
  /// frequency, because they usually mean "the same thing, but monthly".
  RecurrenceRule _ruleFor(
    RecurrenceFrequency frequency,
    RecurrenceRule? current,
  ) => RecurrenceRule(
    frequency: frequency,
    interval: current?.interval ?? 1,
    weekdays: frequency == RecurrenceFrequency.weekly
        ? (current?.weekdays.isNotEmpty ?? false
              ? current!.weekdays
              : [firstDate.weekday])
        : const [],
    until: current?.until,
  );

  String _frequencyLabel(RecurrenceFrequency frequency) => switch (frequency) {
    RecurrenceFrequency.daily => AppCopy.repeatDaily,
    RecurrenceFrequency.weekly => AppCopy.repeatWeekly,
    RecurrenceFrequency.monthly => AppCopy.repeatMonthly,
  };
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});

  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NestSpace.xs,
      runSpacing: NestSpace.sm,
      children: [
        for (var weekday = Weekday.monday; weekday <= Weekday.sunday; weekday++)
          NestChip(
            label: AppCopy.weekdayName(weekday),
            isSelected: selected.contains(weekday),
            onTap: () => onChanged(_toggled(weekday)),
          ),
      ],
    );
  }

  /// Never leaves the rule with no day at all — a weekly rule that repeats on
  /// nothing repeats on nothing, which nobody means.
  List<int> _toggled(int weekday) {
    final next = [...selected];
    if (next.contains(weekday)) {
      if (next.length == 1) return next;
      next.remove(weekday);
    } else {
      next.add(weekday);
    }
    return next..sort();
  }
}
