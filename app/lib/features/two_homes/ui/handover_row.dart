import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/co_parent_link.dart';
import '../model/custody_days.dart';
import '../model/handover_note.dart';
import 'home_swatch.dart';

/// One coming handover on a link's screen: when, to which home, and how far
/// the bag has got — opening the handover when the viewer may read it
/// (household ADR-0004).
class HandoverRow extends StatelessWidget {
  const HandoverRow({
    required this.link,
    required this.childName,
    required this.day,
    required this.today,
    required this.note,
    required this.onTap,
    super.key,
  });

  final CoParentLink link;
  final String childName;
  final CustodyDay day;
  final CalendarDate today;
  final HandoverNote? note;

  /// Null when the viewer's grant does not reach handovers.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final home = link.homeOf(day.side);
    final minute = link.schedule.handoverMinute;
    final when = NestDates.relative(day.date, today);
    final note = this.note;
    final progress = note == null
        ? TwoHomesHandoverCopy.nothingYet
        : note.items.isEmpty
        ? TwoHomesHandoverCopy.lastSavedBy(
            link.homeOf(note.updatedBySide ?? link.ownSide).name,
          )
        : TwoHomesHandoverCopy.packedCount(note.packedCount, note.items.length);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        leading: HomeDot(home: home),
        title: TwoHomesCopy.handoverRow(childName, home.name),
        subtitle: [
          minute == null
              ? when
              : '$when ${TwoHomesCopy.handoverAt(NestDates.timeOfDay(minute))}',
          if (onTap != null) progress,
        ].join(' · '),
        trailing: onTap == null ? null : const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}
