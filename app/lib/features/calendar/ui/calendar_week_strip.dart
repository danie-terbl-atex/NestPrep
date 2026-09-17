import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/calendar_week.dart';

/// Seven days across, with a dot for the days that have something on them. It
/// fits a phone without scrolling sideways, which is the whole reason the week
/// is a strip and not a grid (`FE-14`).
class CalendarWeekStrip extends StatelessWidget {
  const CalendarWeekStrip({
    required this.weekStart,
    required this.today,
    required this.selected,
    required this.daysWithEvents,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final CalendarDate weekStart;
  final CalendarDate today;
  final CalendarDate selected;

  /// The days that have something on them, as `YYYY-MM-DD`. Empty while the
  /// week is still loading — the strip keeps its shape either way (`FE-08`).
  final Set<String> daysWithEvents;
  final ValueChanged<CalendarDate> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  List<CalendarDate> get _days => [
    for (var offset = 0; offset < CalendarWeek.daysInAWeek; offset++)
      weekStart.addDays(offset),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            NestIconButton(
              icon: Icons.chevron_left,
              label: AppCopy.calendarPreviousWeek,
              variant: NestIconButtonVariant.plain,
              onPressed: onPrevious,
            ),
            const Spacer(),
            NestIconButton(
              icon: Icons.chevron_right,
              label: AppCopy.calendarNextWeek,
              variant: NestIconButtonVariant.plain,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: NestSpace.sm),
        Row(
          children: [
            for (final day in _days)
              Expanded(
                child: _DayCell(
                  date: day,
                  isSelected: day == selected,
                  isToday: day == today,
                  hasEvents: daysWithEvents.contains(day.iso),
                  onTap: () => onSelect(day),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasEvents,
    required this.onTap,
  });

  final CalendarDate date;
  final bool isSelected;
  final bool isToday;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ink = isSelected ? nest.colors.onAccent : nest.colors.ink;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${NestDates.weekday(date)} ${NestDates.dayOfMonth(date)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NestRadius.lg),
        child: Padding(
          // The horizontal gutter is not decoration. Seven columns sit edge to
          // edge, and at the largest text size the scaled-down day names meet
          // in the middle and read as one word — MonTueWed. A gap costs a
          // fraction of a point of type and buys seven separate days (`FE-13`).
          padding: const EdgeInsets.symmetric(
            vertical: NestSpace.xs,
            horizontal: NestSpace.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seven columns on a phone leave no room to grow, so the day
              // name shrinks to fit rather than losing a letter (`FE-13`).
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  NestDates.weekday(date),
                  maxLines: 1,
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkTertiary,
                  ),
                ),
              ),
              const SizedBox(height: NestSpace.xxs),
              Container(
                width: NestSize.avatarMedium,
                height: NestSize.avatarMedium,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? nest.colors.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(
                          color: nest.colors.accent,
                          width: NestStroke.focus,
                        )
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    NestDates.dayOfMonth(date),
                    maxLines: 1,
                    style: nest.text.bodyStrong.copyWith(color: ink),
                  ),
                ),
              ),
              const SizedBox(height: NestSpace.xxs),
              // A dot, not a colour on the number: the day still reads without
              // it (`FE-13`).
              SizedBox(
                height: NestSpace.xs,
                child: hasEvents
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? nest.colors.accent
                              : nest.colors.inkTertiary,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: NestSpace.xs),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
