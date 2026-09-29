import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/back_leading.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/state/lunch_board_controller.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_done_panel.dart';
import 'plan_week_options_panel.dart';
import 'plan_week_planning_panel.dart';
import 'plan_week_review.dart';

/// *Plan my week* (lunch-box ADR-0011): choose what to plan, let it be
/// planned, look it over and swap what you like, then use it. The screen only
/// composes; every step is its controller's.
class PlanWeekScreen extends StatelessWidget {
  const PlanWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    return NestScaffold(
      leading: backLeading(context),
      title: PlanWeekCopy.title,
      subtitle: NestDates.weekRange(controller.week.monday),
      body: AnimatedSwitcher(
        duration: NestMotion.of(context).standard,
        child: KeyedSubtree(
          key: ValueKey(_panelOf(controller.step)),
          child: switch (controller.step) {
            PlanWeekStep.choosing => NestAsyncView<LunchBoard>(
              state: controller.board,
              // No children is not empty here: dinners can still be planned.
              isEmpty: (_) => false,
              emptyBuilder: (_) => const SizedBox.shrink(),
              onRetry: context.read<LunchBoardController>().retry,
              dataBuilder: (context, board) =>
                  PlanWeekOptionsPanel(board: board),
            ),
            PlanWeekStep.planning => const PlanWeekPlanningPanel(),
            PlanWeekStep.review ||
            PlanWeekStep.saving => const PlanWeekReview(),
            PlanWeekStep.done => const PlanWeekDonePanel(),
          },
        ),
      ),
    );
  }

  /// Saving stays on the review, so the list does not fade out and back.
  static PlanWeekStep _panelOf(PlanWeekStep step) =>
      step == PlanWeekStep.saving ? PlanWeekStep.review : step;
}
