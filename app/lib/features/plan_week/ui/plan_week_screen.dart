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
import 'plan_week_store_panel.dart';
import 'plan_week_week_name.dart';
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
      subtitle: _subtitle(controller),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestStepsBar(
            count: PlanWeekStep.values.length,
            index: controller.step.index,
            label: PlanWeekCopy.stepOf(
              controller.step.index + 1,
              PlanWeekCopy.stepNames(
                controller.retailer.shop,
              )[controller.step.index],
            ),
          ),
          const SizedBox(height: NestSpace.lg),
          Expanded(
            // Twig swaps in mid-flow — the drafting and building waits, the
            // done step — so its poses are decoded before it is needed.
            child: NestTwigWarmUp(
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
          ),
        ],
      ),
    );
  }

  /// "Next week · 12 – 18 Oct": which week is being planned, then its dates
  /// (lunch-box ADR-0019); the dates alone for a week further off.
  static String _subtitle(PlanWeekController controller) {
    final dates = NestDates.weekRange(controller.week.monday);
    final name = planWeekName(controller);
    return name.isNear ? PlanWeekCopy.namedWeek(name.label, dates) : dates;
  }
}
