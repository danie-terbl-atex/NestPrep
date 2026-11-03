import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/calendar_month.dart';
import '../model/calendar_week.dart';

/// The month the calendar opens on (design-system ADR-0017): whole weeks,
/// Monday first, each day with up to three dots in the colours of whoever has
/// something on. The dots are never the only signal — the day's agenda under
/// the grid names everything, and each day's label says how much is on
/// (`FE-13`).
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.dotsByDay,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final CalendarMonth month;
  final CalendarDate today;
  final CalendarDate selected;

  /// Per `YYYY-MM-DD`, how many things are on and in whose colours — null for
  /// one that is nobody's in particular. Empty while the month is loading, and
  /// the grid keeps its shape either way (`FE-08`).
  final Map<String, DayDots> dotsByDay;
  final ValueChanged<CalendarDate> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  static const shownDots = 3;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final start = month.gridStart;
    final weeks = month.gridDays ~/ CalendarWeek.daysInAWeek;
    return Column(
      children: [
        Row(
          children: [
            NestIconButton(
              icon: LucideIcons.chevronLeft,
              label: AppCopy.calendarPreviousMonth,
              variant: NestIconButtonVariant.plain,
              onPressed: onPrevious,
            ),
            Expanded(
              child: Text(
                NestDates.monthAndYear(month.first),
                textAlign: TextAlign.center,
                style: nest.text.title,
              ),
            ),
            NestIconButton(
              icon: LucideIcons.chevronRight,
              label: AppCopy.calendarNextMonth,
              variant: NestIconButtonVariant.plain,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: NestSpace.sm),
        ExcludeSemantics(
          child: Row(
            children: [
              for (var day = 0; day < CalendarWeek.daysInAWeek; day++)
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      NestDates.weekday(start.addDays(day)),
                      maxLines: 1,
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.xs),
        for (var week = 0; week < weeks; week++)
          Row(
            children: [
              for (var day = 0; day < CalendarWeek.daysInAWeek; day++)
                Expanded(
                  child: _MonthDay(
                    date: start.addDays(week * CalendarWeek.daysInAWeek + day),
                    month: month,
                    today: today,
                    selected: selected,
                    dots: dotsByDay,
                    onSelect: onSelect,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// What a day of the grid shows under its number.
typedef DayDots = ({int count, List<MemberColor?> colors});

class _MonthDay extends StatelessWidget {
  const _MonthDay({
    required this.date,
    required this.month,
    required this.today,
    required this.selected,
    required this.dots,
    required this.onSelect,
  });

  final CalendarDate date;
  final CalendarMonth month;
  final CalendarDate today;
  final CalendarDate selected;
  final Map<String, DayDots> dots;
  final ValueChanged<CalendarDate> onSelect;

  /// Seven of these fit 320 dp, a 360-wide phone inside its gutters.
  static const _cellWidth = 40.0;

  /// Three of these and their gaps fit under the number.
  static const _dot = NestSpace.xs + NestSpace.xxs;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final isSelected = date == selected;
    final isToday = date == today;
    final isInMonth = month.contains(date);
    final day = dots[date.iso];
    final ink = isSelected
        ? nest.colors.secondaryInk
        : isInMonth
        ? nest.colors.ink
        : nest.colors.inkTertiary;
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${NestDates.weekday(date)} ${NestDates.dayOfMonth(date)} '
          '${NestDates.monthAndYear(date)}, '
          '${AppCopy.calendarDayHas(day?.count ?? 0)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onSelect(date),
        borderRadius: BorderRadius.circular(NestRadius.lg),
        child: SizedBox(
          height: NestSize.controlMedium + NestSpace.sm,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The selected day takes the tonal teal, today a ring, the same
              // as the week strip (design-system ADR-0003).
              Container(
                width: _cellWidth,
                height: NestSpace.xxxl,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? nest.colors.secondarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(NestRadius.md),
                  border: isToday || isSelected
                      ? Border.all(
                          color: nest.colors.secondary,
                          width: NestStroke.focus,
                        )
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    NestDates.dayOfMonth(date),
                    maxLines: 1,
                    style: (isInMonth ? nest.text.bodyStrong : nest.text.body)
                        .copyWith(color: ink),
                  ),
                ),
              ),
              const SizedBox(height: NestSpace.xxs),
              SizedBox(
                height: _dot,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final color
                        in (day?.colors ?? const <MemberColor?>[]).take(
                          CalendarMonthGrid.shownDots,
                        ))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NestSpace.xxs / 2,
                        ),
                        child: color == null
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  color: nest.colors.inkTertiary,
                                  shape: BoxShape.circle,
                                ),
                                child: const SizedBox.square(dimension: _dot),
                              )
                            : NestDot(color: color, size: _dot),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
