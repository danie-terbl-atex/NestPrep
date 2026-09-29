import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/co_parent_home.dart';
import '../model/custody_side.dart';

/// Two weeks of a child's days, a row a week, each day in the colour of the
/// home they are with (household ADR-0004). It is the schedule's picture on
/// every screen that shows one — the preview while choosing, the custom
/// editor when [onTapDay] is given, and the next fortnight of a live link.
///
/// Each day is labelled for a screen reader with the date and the home, and
/// the day a child changes homes carries an arrow, so the colour is never
/// the only signal (`FE-13`).
class FortnightStrip extends StatelessWidget {
  const FortnightStrip({
    required this.start,
    required this.sides,
    required this.homeOf,
    this.onTapDay,
    super.key,
  });

  /// The first day shown.
  final CalendarDate start;

  /// One side per day from [start]; null is a day the schedule has not
  /// reached yet.
  final List<CustodySide?> sides;
  final CoParentHome Function(CustodySide side) homeOf;

  /// Flips a day in the custom editor. Null draws the strip read-only.
  final ValueChanged<int>? onTapDay;

  static const daysInAWeek = 7;

  @override
  Widget build(BuildContext context) {
    final weeks = (sides.length / daysInAWeek).ceil();
    return Column(
      children: [
        for (var week = 0; week < weeks; week++) ...[
          if (week > 0) const SizedBox(height: NestSpace.xs),
          Row(
            children: [
              for (
                var index = week * daysInAWeek;
                index < (week + 1) * daysInAWeek;
                index++
              )
                Expanded(
                  child: index >= sides.length
                      ? const SizedBox.shrink()
                      : _DayCell(
                          date: start.addDays(index),
                          home: switch (sides[index]) {
                            final side? => homeOf(side),
                            null => null,
                          },
                          isHandover:
                              index > 0 &&
                              sides[index] != null &&
                              sides[index - 1] != null &&
                              sides[index - 1] != sides[index],
                          onTap: onTapDay == null
                              ? null
                              : () => onTapDay?.call(index),
                        ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.home,
    required this.isHandover,
    required this.onTap,
  });

  final CalendarDate date;
  final CoParentHome? home;
  final bool isHandover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final home = this.home;
    final swatch = home == null ? null : nest.members.of(home.color);
    final ink = swatch?.onFill ?? nest.colors.inkTertiary;
    final label =
        '${NestDates.weekday(date)} ${NestDates.dayOfMonth(date)}'
        '${home == null ? '' : ', ${TwoHomesCopy.dayWith(home.name)}'}';
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NestSpace.xxs),
        child: Material(
          color: swatch?.fill ?? nest.colors.surfaceTint,
          borderRadius: BorderRadius.circular(NestRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(NestRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: NestSize.controlSmall,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        NestDates.weekday(date).substring(0, 1),
                        style: nest.text.caption.copyWith(color: ink),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: isHandover
                          ? Icon(
                              Icons.swap_horiz,
                              size: NestSize.iconSmall,
                              color: ink,
                            )
                          : Text(
                              NestDates.dayOfMonth(date),
                              style: nest.text.label.copyWith(color: ink),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
