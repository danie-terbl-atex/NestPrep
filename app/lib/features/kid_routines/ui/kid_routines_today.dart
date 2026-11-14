import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/kid_routine_run.dart';
import '../state/kid_routine_day_controller.dart';
import 'kid_routine_player.dart';
import 'kid_routine_today_card.dart';

/// Today's routines on a child's home (kid-routines ADR-0001). A day with
/// none, a read still on its way and a read that failed all take no room:
/// the jobs under it are the page, and a routine is never the reason a child
/// sees an error.
class KidRoutinesToday extends StatelessWidget {
  const KidRoutinesToday({
    required this.controller,
    required this.kidName,
    super.key,
  });

  final KidRoutineDayController controller;
  final String kidName;

  @override
  Widget build(BuildContext context) {
    final runs = switch (controller.runs) {
      AsyncData(:final value) => value,
      _ => const <KidRoutineRun>[],
    };
    if (runs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NestSpace.xxl),
        const NestSectionHeader(title: KidRoutineCopy.kidTitle),
        const SizedBox(height: NestSpace.sm),
        for (final (index, run) in runs.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestRiseIn(
              index: index + 1,
              child: KidRoutineTodayCard(
                key: ValueKey('kid-routine-${run.routine.id}'),
                run: run,
                canTick: controller.canTick,
                onOpen: () => showKidRoutinePlayer(
                  context,
                  controller: controller,
                  routineId: run.routine.id,
                  kidName: kidName,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
