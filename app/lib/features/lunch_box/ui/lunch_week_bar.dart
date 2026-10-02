import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/lunch_week.dart';

/// The school week on show, with a step either side and a way back to this
/// week when somebody has wandered.
class LunchWeekBar extends StatelessWidget {
  const LunchWeekBar({
    required this.week,
    required this.isThisWeek,
    required this.onPrevious,
    required this.onNext,
    required this.onThisWeek,
    required this.planningWeek,
    super.key,
  });

  final LunchWeek week;
  final bool isThisWeek;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onThisWeek;

  /// The week the parent is planning is always given the same week the
  /// controller calls "this week" — `LunchWeek.planningFor`.
  final LunchWeek planningWeek;

  /// "This week", "Next week", "Last week", or the dates of one further off
  /// — the header already says the dates, so the bar says where you are.
  String get _name => switch (planningWeek.weeksUntil(week)) {
    0 => LunchCopy.thisWeek,
    1 => LunchCopy.nextWeekName,
    -1 => LunchCopy.lastWeek,
    _ => NestDates.schoolWeekRange(week.monday),
  };

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Row(
      children: [
        NestIconButton(
          icon: LucideIcons.chevronLeft,
          label: LunchCopy.previousWeek,
          variant: NestIconButtonVariant.plain,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                _name,
                textAlign: TextAlign.center,
                style: nest.text.bodyStrong,
              ),
              if (!isThisWeek)
                NestButton(
                  label: LunchCopy.backToThisWeek,
                  variant: NestButtonVariant.ghost,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: onThisWeek,
                ),
            ],
          ),
        ),
        NestIconButton(
          icon: LucideIcons.chevronRight,
          label: LunchCopy.nextWeek,
          variant: NestIconButtonVariant.plain,
          onPressed: onNext,
        ),
      ],
    );
  }
}
