import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/household_view.dart';
import '../model/event_occurrence.dart';
import '../state/calendar_controller.dart';
import 'event_sheet.dart';

/// One event on one day. The member colours run down the left edge, with the
/// names in the subtitle — colour is never the only thing saying who it is for
/// (`FE-13`, calendar ADR-0001).
class EventRow extends StatelessWidget {
  const EventRow({required this.occurrence, required this.today, super.key});

  final EventOccurrence occurrence;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final view = context.read<HouseholdView>();
    final event = occurrence.event;
    final members = [for (final id in event.memberIds) ?view.memberById(id)];

    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(NestRadius.lg),
        onTap: () => _edit(context, view),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MemberStripe(
                colors: [for (final member in members) member.color],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(NestSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: nest.text.bodyStrong.copyWith(
                          color: nest.colors.ink,
                        ),
                      ),
                      const SizedBox(height: NestSpace.xxs),
                      Text(
                        _subtitle(members.map((m) => m.displayName).toList()),
                        style: nest.text.caption.copyWith(
                          color: nest.colors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(List<String> memberNames) {
    final event = occurrence.event;
    final when = event.isAllDay
        ? AppCopy.calendarAllDay
        : _timeRange(event.startMinute!, event.endMinute);
    final who = memberNames.isEmpty
        ? AppCopy.calendarEveryone
        : memberNames.join(', ');
    return '$when · $who';
  }

  String _timeRange(int startMinute, int? endMinute) {
    final start = NestDates.timeOfDay(startMinute);
    if (endMinute == null) return start;
    return '$start – ${NestDates.timeOfDay(endMinute)}';
  }

  Future<void> _edit(BuildContext context, HouseholdView view) async {
    final controller = context.read<CalendarController>();
    final draft = await showEventSheet(
      context: context,
      members: view.members,
      today: today,
      initialDate: occurrence.date,
      existing: occurrence.event,
      canSkip: occurrence.event.recurrence != null,
    );
    switch (draft) {
      case null:
        return;
      case EventDeleted():
        await controller.deleteEvent(occurrence.event.id);
      case EventSkipped():
        await controller.skip(occurrence);
      case EventSaved():
        await controller.saveEvent(
          eventId: occurrence.event.id,
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
}

/// The colours of everybody an event is for, stacked down its left edge.
class _MemberStripe extends StatelessWidget {
  const _MemberStripe({required this.colors});

  final List<MemberColor> colors;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final stripes = colors.isEmpty
        ? [nest.colors.outlineStrong]
        : [for (final color in colors) nest.members.of(color).fill];
    return SizedBox(
      width: NestSpace.xs,
      child: Column(
        children: [
          for (final color in stripes)
            Expanded(child: ColoredBox(color: color)),
        ],
      ),
    );
  }
}
