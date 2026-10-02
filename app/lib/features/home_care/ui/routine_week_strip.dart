import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/routine/routine_board.dart';

/// This week at a glance for the parent (home-care ADR-0004): each day, how
/// much of its routines was ticked — so Monday's missed kitchen shows on
/// Wednesday. Said in words, the tone only agreeing (`FE-13`).
class RoutineWeekStrip extends StatelessWidget {
  const RoutineWeekStrip({required this.board, super.key});

  final RoutineBoard board;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        for (final day in board.week)
          Builder(
            builder: (context) {
              final (:done, :due) = board.progressOn(day);
              final isPast = day.isBefore(board.today);
              return NestTag(
                label: HomeCareRoutineCopy.dayProgress(
                  AppCopy.weekdayName(day.weekday),
                  done,
                  due,
                  isToday: day == board.today,
                ),
                icon: due > 0 && done == due ? LucideIcons.circleCheck : null,
                tone: switch ((due, done)) {
                  (0, _) => NestTagTone.neutral,
                  _ when done == due => NestTagTone.success,
                  _ when isPast => NestTagTone.warning,
                  _ => NestTagTone.accent,
                },
              );
            },
          ),
      ],
    );
  }
}
