import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../model/nanny_pickups.dart';
import '../model/pickup_change.dart';
import 'collector_look.dart';

/// The days that are not like the week, soonest first. Each says the day,
/// the child and who comes instead — or that nobody does. The add control
/// stays beside the empty message (`FE-08`).
class PickupChangesSection extends StatelessWidget {
  const PickupChangesSection({
    required this.pickups,
    required this.today,
    required this.memberById,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final NannyPickups pickups;
  final CalendarDate today;
  final Member? Function(String memberId) memberById;

  /// Null for anybody who is not family.
  final VoidCallback? onAdd;
  final ValueChanged<PickupChange>? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final edit = onEdit;
    final upcoming = [
      for (final change in pickups.changes)
        if (!change.date.isBefore(today)) change,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestSectionHeader(
          title: NannyPickupCopy.changes,
          actionIcon: onAdd == null ? null : Icons.event_available_outlined,
          actionLabel: onAdd == null ? null : NannyPickupCopy.addChange,
          onAction: onAdd,
        ),
        const SizedBox(height: NestSpace.sm),
        if (upcoming.isEmpty)
          Text(NannyPickupCopy.noChanges, style: nest.text.bodySecondary),
        for (final change in upcoming)
          Padding(
            key: ValueKey(change.id),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestCard(
              variant: NestCardVariant.flat,
              padding: EdgeInsets.zero,
              child: NestListRow(
                leading: const NestIconTile(
                  icon: Icons.event_repeat,
                  tint: NestTileTint.peach,
                ),
                title:
                    '${NestDates.relative(change.date, today)} · '
                    '${memberById(change.childId)?.displayName ?? ''}',
                subtitle: [
                  lookOfCollector(
                    change.collector,
                    pickups: pickups,
                    memberById: memberById,
                  ).name,
                  if (change.atMinute case final minute?)
                    NestDates.timeOfDay(minute),
                  ?change.note,
                ].join(' · '),
                trailing: edit == null ? null : const Icon(Icons.chevron_right),
                onTap: edit == null ? null : () => edit(change),
              ),
            ),
          ),
      ],
    );
  }
}
