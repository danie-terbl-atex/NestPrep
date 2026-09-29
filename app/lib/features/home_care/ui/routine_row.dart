import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/routine/room_routine.dart';
import 'routine_cadence_look.dart';

/// One room routine in the overview: its name, how often, who, and how much
/// is on it (home-care ADR-0004).
class RoutineRow extends StatelessWidget {
  const RoutineRow({
    required this.routine,
    required this.helperName,
    required this.onTap,
    super.key,
  });

  final RoomRoutine routine;
  final String helperName;

  /// Null for somebody who reads the routines but does not keep them.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: routine.name,
        subtitle: HomeCareRoutineCopy.summary(
          HomeCareRoutineCopy.cadenceName(routine.cadence),
          AppCopy.recurrenceSummary(routine.recurrence),
          helperName,
          routine.items.length,
        ),
        leading: NestIconTile(
          icon: routine.cadence.icon,
          tint: routine.cadence.tint,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
