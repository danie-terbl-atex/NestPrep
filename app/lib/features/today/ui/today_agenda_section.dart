import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../calendar/model/calendar_week.dart';
import '../../calendar/model/day_entry.dart';
import '../../calendar/state/calendar_controller.dart';
import 'today_async.dart';
import 'today_section.dart';

/// Today's calendar, time first, opening the week.
class TodayAgendaSection extends StatelessWidget {
  const TodayAgendaSection({required this.onOpen, super.key});

  final VoidCallback onOpen;

  static const _shown = 4;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<CalendarController>();
    return TodaySection(
      eyebrow: TodayCopy.agendaEyebrow,
      actionLabel: TodayCopy.seeTheWeek,
      onAction: onOpen,
      child: TodayAsync<CalendarWeek>(
        state: controller.week,
        builder: (context, week) {
          final entries = week.on(week.today);
          if (entries.isEmpty) {
            return Text(TodayCopy.agendaEmpty, style: nest.text.bodySecondary);
          }
          return NestCard(
            padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
            child: Column(
              children: [
                for (final entry in entries.take(_shown))
                  NestListRow(
                    title: _title(entry),
                    leading: SizedBox(
                      width: NestSize.avatarLarge + NestSpace.md,
                      child: Text(_time(entry), style: nest.text.label),
                    ),
                    onTap: onOpen,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _title(DayEntry entry) => switch (entry) {
    EventEntry(:final occurrence) => occurrence.event.title,
    BirthdayEntry(:final birthday) => AppCopy.birthdayOf(
      birthday.member.displayName,
    ),
    SyncedEntry(:final event) => event.title,
  };

  static String _time(DayEntry entry) {
    final minute = switch (entry) {
      EventEntry(:final occurrence) => occurrence.event.startMinute,
      BirthdayEntry() => null,
      SyncedEntry(:final event) => event.isAllDay ? null : event.startMinute,
    };
    return minute == null ? TodayCopy.allDay : NestDates.timeOfDay(minute);
  }
}
