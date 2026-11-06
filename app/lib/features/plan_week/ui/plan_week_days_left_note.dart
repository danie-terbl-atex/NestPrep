import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../lunch_box/model/lunch_week.dart';

/// Which of the week's school days have gone and which are left, said once
/// so a week planned mid-way reads as the days it covers, not as empty days
/// (lunch-box ADR-0019). Nothing when the whole week is still to come.
class PlanWeekDaysLeftNote extends StatelessWidget {
  const PlanWeekDaysLeftNote({
    required this.week,
    required this.daysLeft,
    super.key,
  });

  final LunchWeek week;
  final Set<int> daysLeft;

  @override
  Widget build(BuildContext context) {
    final days = week.schoolDays;
    if (daysLeft.length == days.length) return const SizedBox.shrink();
    return NestBanner(
      key: const ValueKey('plan-week-days-left'),
      message: PlanWeekCopy.daysLeft(
        left: [
          for (final day in days)
            if (daysLeft.contains(day.weekday)) NestDates.weekdayName(day),
        ],
        gone: [
          for (final day in days)
            if (!daysLeft.contains(day.weekday)) NestDates.weekdayName(day),
        ],
      ),
    );
  }
}
