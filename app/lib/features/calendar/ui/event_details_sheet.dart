import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../assistants/ui/assistant_via_mark.dart';
import '../../avatars/ui/member_avatar.dart';
import '../../household/model/member.dart';
import '../model/event_occurrence.dart';
import 'event_row.dart';

/// One event as somebody reads it: what, when, how often, who and its notes.
/// Answers true when they asked to edit it, which only [canEdit] offers.
Future<bool> showEventDetailsSheet({
  required BuildContext context,
  required EventOccurrence occurrence,
  required List<Member> members,
  required CalendarDate today,
  required bool canEdit,
}) async =>
    await showNestSheet<bool>(
      context: context,
      title: AppCopy.calendarEventDetails,
      builder: (sheetContext) => _EventDetails(
        occurrence: occurrence,
        members: members,
        today: today,
        canEdit: canEdit,
      ),
    ) ??
    false;

class _EventDetails extends StatelessWidget {
  const _EventDetails({
    required this.occurrence,
    required this.members,
    required this.today,
    required this.canEdit,
  });

  final EventOccurrence occurrence;
  final List<Member> members;
  final CalendarDate today;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final event = occurrence.event;
    final via = event.createdVia;
    final note = event.note?.trim();
    final recurrence = event.recurrence;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(event.title, style: nest.text.headline),
          if (via != null) ...[
            const SizedBox(height: NestSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AssistantViaMark(via: via),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          NestListRow(
            title: NestDates.full(occurrence.date, today),
            subtitle: EventRow.timeOf(event),
            leading: const NestIconTile(
              icon: LucideIcons.calendarClock,
              tint: NestTileTint.butter,
              size: NestSize.avatarMedium,
            ),
          ),
          if (recurrence != null)
            NestListRow(
              title: AppCopy.recurrenceSummary(recurrence),
              subtitle: AppCopy.calendarRepeats,
              leading: const NestIconTile(
                icon: LucideIcons.repeat,
                tint: NestTileTint.basil,
                size: NestSize.avatarMedium,
              ),
            ),
          NestListRow(
            title: members.isEmpty
                ? AppCopy.calendarEveryone
                : members.map((member) => member.displayName).join(', '),
            subtitle: AppCopy.calendarForLabel,
            leading: members.isEmpty
                ? const NestIconTile(
                    icon: LucideIcons.users,
                    tint: NestTileTint.guava,
                    size: NestSize.avatarMedium,
                  )
                : MemberAvatar(member: members.first),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: NestSpace.lg),
            NestCard(
              variant: NestCardVariant.flat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.notebookPen,
                        size: NestSize.iconSmall,
                        color: nest.colors.inkSecondary,
                      ),
                      const SizedBox(width: NestSpace.sm),
                      Text(
                        AppCopy.calendarNotesLabel,
                        style: nest.text.label.copyWith(
                          color: nest.colors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NestSpace.sm),
                  SelectableText(note, style: nest.text.reading),
                ],
              ),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: NestSpace.xl),
            NestButton(
              label: AppCopy.calendarEditEvent,
              icon: LucideIcons.pencil,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ],
      ),
    );
  }
}
