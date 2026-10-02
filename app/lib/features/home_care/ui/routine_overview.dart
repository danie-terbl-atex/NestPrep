import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/routine/room_routine.dart';
import '../model/routine/routine_board.dart';
import 'room_day_header.dart';
import 'routine_row.dart';
import 'routine_week_strip.dart';

/// The parent's overview of the room routines (home-care ADR-0004): how far
/// each room is today, and every routine, room by room.
class RoutineOverview extends StatelessWidget {
  const RoutineOverview({
    required this.board,
    required this.onOpenToday,
    required this.onEdit,
    super.key,
  });

  final RoutineBoard board;
  final VoidCallback onOpenToday;

  /// Null for somebody who reads the routines but does not keep them.
  final ValueChanged<RoomRoutine>? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final today = board.roomsOn(board.today);
    final edit = onEdit;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        const NestSectionHeader(title: HomeCareRoutineCopy.weekHeading),
        RoutineWeekStrip(board: board),
        const SizedBox(height: NestSpace.md),
        NestSectionHeader(
          title: HomeCareRoutineCopy.todayHeading,
          actionIcon: LucideIcons.arrowRight,
          actionLabel: HomeCareRoutineCopy.openToday,
          onAction: onOpenToday,
        ),
        if (today.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: Text(
              HomeCareRoutineCopy.nothingTodayBody,
              style: nest.text.bodySecondary,
            ),
          ),
        for (final day in today)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestCard(
              variant: NestCardVariant.flat,
              padding: const EdgeInsets.all(NestSpace.lg),
              onTap: onOpenToday,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RoomDayHeader(day: day),
                  const SizedBox(height: NestSpace.sm),
                  for (final visit in day.visits)
                    Text(
                      HomeCareRoutineCopy.routineAndWho(
                        visit.routine.name,
                        _who(visit.routine),
                      ),
                      style: nest.text.caption,
                    ),
                ],
              ),
            ),
          ),
        const NestSectionHeader(title: HomeCareRoutineCopy.everyRoutineHeading),
        for (final (room, _, routines) in board.routinesByRoom) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: Text(
              room?.name ?? HomeCareRoutineCopy.roomGone,
              style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
            ),
          ),
          for (final routine in routines)
            Padding(
              key: ValueKey(routine.id),
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: RoutineRow(
                routine: routine,
                helperName: _who(routine),
                onTap: edit == null ? null : () => edit(routine),
              ),
            ),
          const SizedBox(height: NestSpace.md),
        ],
      ],
    );
  }

  String _who(RoomRoutine routine) =>
      board.memberById(routine.helperId)?.displayName ??
      HomeCareRoutineCopy.helperGone;
}
