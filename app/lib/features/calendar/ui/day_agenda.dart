import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/household_view.dart';
import '../model/calendar_week.dart';
import '../state/calendar_controller.dart';
import 'event_row.dart';
import 'event_sheet.dart';

/// One day, all-day events first and then by the time they start (calendar
/// ADR-0001). The empty state names the day, so it never reads as a failure.
class DayAgenda extends StatelessWidget {
  const DayAgenda({required this.week, required this.day, super.key});

  final CalendarWeek week;
  final CalendarDate day;

  @override
  Widget build(BuildContext context) {
    final occurrences = week.on(day);
    final controller = context.read<CalendarController>();
    final view = context.read<HouseholdView>();

    if (occurrences.isEmpty) {
      return NestEmptyView(
        title:
            '${AppCopy.calendarDayEmpty} '
            '${NestDates.relative(day, week.today).toLowerCase()}',
        message: AppCopy.calendarEmptyBody,
        icon: Icons.event_available_outlined,
        actionLabel: AppCopy.calendarAddEvent,
        onAction: () => _add(context, controller, view, day),
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

  Future<void> _add(
    BuildContext context,
    CalendarController controller,
    HouseholdView view,
    CalendarDate date,
  ) async {
    final draft = await showEventSheet(
      context: context,
      members: view.members,
      today: controller.today,
      initialDate: date,
    );
    if (draft is! EventSaved) return;
    await controller.saveEvent(
      title: draft.title,
      note: draft.note,
      date: draft.date,
      startMinute: draft.startMinute,
      endMinute: draft.endMinute,
      recurrence: draft.recurrence,
      memberIds: draft.memberIds,
    );
  }
}
