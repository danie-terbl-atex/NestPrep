import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/calendar_week.dart';
import 'event_row.dart';

/// One day, all-day events first and then by the time they start (calendar
/// ADR-0001). The empty state names the day, so it never reads as a failure.
class DayAgenda extends StatelessWidget {
  const DayAgenda({required this.week, required this.day, super.key});

  final CalendarWeek week;
  final CalendarDate day;

  @override
  Widget build(BuildContext context) {
    final occurrences = week.on(day);

    if (occurrences.isEmpty) {
      // No action here: the screen's own "Add an event" button is a thumb's
      // reach away, and two identical calls to action read as a mistake.
      return NestEmptyView(
        title:
            '${AppCopy.calendarDayEmpty} '
            '${NestDates.relative(day, week.today).toLowerCase()}',
        message: AppCopy.calendarEmptyBody,
        icon: Icons.event_available_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
        NestSectionHeader(title: NestDates.relative(day, week.today)),
        const SizedBox(height: NestSpace.sm),
        for (final occurrence in occurrences)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: EventRow(
              key: ValueKey(occurrence.key),
              occurrence: occurrence,
              today: week.today,
            ),
          ),
      ],
    );
  }
}
