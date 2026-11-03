import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../calendar/model/calendar_week.dart';
import '../../calendar/model/day_entry.dart';
import '../../calendar/state/calendar_controller.dart';
import '../../calendar/ui/entry_colors.dart';
import '../../calendar/ui/member_stripe.dart';
import '../../household/model/household_view.dart';
import 'today_async.dart';
import 'today_section.dart';

/// Today's calendar, time first, and what is coming up in the rest of the
/// week — the first thing on Today (design-system ADR-0017), opening the
/// Calendar tab.
class TodayAgendaSection extends StatelessWidget {
  const TodayAgendaSection({required this.onOpen, super.key});

  final VoidCallback onOpen;

  static const _shownToday = 5;
  static const _shownAhead = 3;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<CalendarController>();
    final view = context.read<HouseholdView>();
    return TodaySection(
      eyebrow: TodayCopy.agendaEyebrow,
      actionLabel: TodayCopy.openCalendar,
      onAction: onOpen,
      child: TodayAsync<CalendarWeek>(
        state: controller.week,
        builder: (context, week) {
          final today = week.on(week.today);
          final ahead = [
            for (final day in week.days)
              if (day.isAfter(week.today)) ...week.on(day),
          ].take(_shownAhead).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (today.isEmpty)
                NestCard(
                  variant: NestCardVariant.tinted,
                  onTap: onOpen,
                  child: Text(
                    TodayCopy.agendaEmpty,
                    style: nest.text.bodySecondary,
                  ),
                )
              else
                _Entries(
                  entries: today.take(_shownToday).toList(),
                  view: view,
                  leadOf: _time,
                  onOpen: onOpen,
                ),
              if (ahead.isNotEmpty) ...[
                const SizedBox(height: NestSpace.lg),
                Text(
                  TodayCopy.comingUp,
                  style: nest.text.label.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
                const SizedBox(height: NestSpace.sm),
                _Entries(
                  entries: ahead,
                  view: view,
                  leadOf: (entry) => NestDates.weekday(entry.date),
                  subtitleOf: _time,
                  onOpen: onOpen,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _time(DayEntry entry) {
    final minute = switch (entry) {
      EventEntry(:final occurrence) => occurrence.event.startMinute,
      BirthdayEntry() => null,
      SyncedEntry(:final event) => event.isAllDay ? null : event.startMinute,
    };
    return minute == null ? TodayCopy.allDay : NestDates.timeOfDay(minute);
  }
}

/// A card of a day's lines: the members' colours down the edge, a short lead
/// (the time, or the weekday ahead), the title, and who it is for — colour is
/// never the only thing saying whose it is (`FE-13`).
class _Entries extends StatelessWidget {
  const _Entries({
    required this.entries,
    required this.view,
    required this.leadOf,
    required this.onOpen,
    this.subtitleOf,
  });

  final List<DayEntry> entries;
  final HouseholdView view;
  final String Function(DayEntry entry) leadOf;
  final String Function(DayEntry entry)? subtitleOf;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: Column(
        children: [
          for (final entry in entries)
            NestListRow(
              title: _title(entry),
              subtitle: _subtitle(entry),
              // Sized by its words rather than a fixed column, so the time
              // is whole at 200% text (`FE-13`).
              leading: SizedBox(
                height: NestSize.avatarMedium,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MemberStripe(colors: entryColors(entry, view)),
                    const SizedBox(width: NestSpace.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: NestSize.avatarLarge,
                      ),
                      child: Text(
                        leadOf(entry),
                        maxLines: 1,
                        style: nest.text.label,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: onOpen,
            ),
        ],
      ),
    );
  }

  String? _subtitle(DayEntry entry) {
    final names = switch (entry) {
      EventEntry(:final occurrence) => [
        for (final id in occurrence.event.memberIds)
          ?view.memberById(id)?.displayName.split(' ').first,
      ],
      BirthdayEntry() => const <String>[],
      SyncedEntry(:final event) => [
        ?view.memberById(event.memberId)?.displayName.split(' ').first,
      ],
    };
    final parts = [?subtitleOf?.call(entry), ...names];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String _title(DayEntry entry) => switch (entry) {
    EventEntry(:final occurrence) => occurrence.event.title,
    BirthdayEntry(:final birthday) => AppCopy.birthdayOf(
      birthday.member.displayName,
    ),
    SyncedEntry(:final event) => event.title,
  };
}
