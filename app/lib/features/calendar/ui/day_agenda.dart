import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/calendar_week.dart';
import '../model/day_entry.dart';
import 'birthday_row.dart';
import 'event_row.dart';

/// One day: birthdays first, then the all-day events and then the rest by the
/// time they start (calendar ADR-0001, birthdays ADR-0001). The empty state
/// names the day, so it never reads as a failure.
class DayAgenda extends StatelessWidget {
  const DayAgenda({
    required this.week,
    required this.day,
    required this.householdId,
    super.key,
  });

  final CalendarWeek week;
  final CalendarDate day;

  /// Where a birthday row goes when it is tapped: the household's profiles,
  /// which is the only place a birthday can be changed.
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final entries = week.on(day);

    if (entries.isEmpty) {
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
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: switch (entry) {
              EventEntry(:final occurrence) => EventRow(
                key: ValueKey(entry.key),
                occurrence: occurrence,
                today: week.today,
              ),
              BirthdayEntry(:final birthday) => BirthdayRow(
                key: ValueKey(entry.key),
                occurrence: birthday,
                householdId: householdId,
              ),
            },
          ),
      ],
    );
  }
}
