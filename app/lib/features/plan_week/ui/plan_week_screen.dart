import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/back_leading.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/state/lunch_board_controller.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_brief_panel.dart';
import 'plan_week_done_panel.dart';
import 'plan_week_ideas_panel.dart';
import 'plan_week_steps_bar.dart';
import 'plan_week_store_panel.dart';
import 'plan_week_week_panel.dart';

/// *Plan my week from Checkers* (lunch-box ADR-0012): five steps, the one
/// showing named at the top, each saying what it does and confirmed before
/// the next. The screen only composes; every step is its controller's.
class PlanWeekScreen extends StatelessWidget {
  const PlanWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    return NestScaffold(
      leading: backLeading(context),
      title: PlanWeekCopy.title,
      subtitle: NestDates.weekRange(controller.week.monday),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlanWeekStepsBar(step: controller.step),
          const SizedBox(height: NestSpace.lg),
          Expanded(
            child: AnimatedSwitcher(
              duration: NestMotion.of(context).standard,
              child: KeyedSubtree(
                key: ValueKey(controller.step),
                child: switch (controller.step) {
                  PlanWeekStep.brief => NestAsyncView<LunchBoard>(
                    state: controller.board,
                    // No children is said by the brief itself.
                    isEmpty: (_) => false,
                    emptyBuilder: (_) => const SizedBox.shrink(),
                    onRetry: context.read<LunchBoardController>().retry,
                    dataBuilder: (context, board) =>
                        PlanWeekBriefPanel(board: board),
                  ),
                  PlanWeekStep.ideas => const PlanWeekIdeasPanel(),
                  PlanWeekStep.store => const PlanWeekStorePanel(),
                  PlanWeekStep.week => const PlanWeekWeekPanel(),
                  PlanWeekStep.done => const PlanWeekDonePanel(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
