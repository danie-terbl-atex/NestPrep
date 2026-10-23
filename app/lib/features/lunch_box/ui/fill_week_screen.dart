import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/lunch_board.dart';
import '../state/fill_week_controller.dart';
import '../state/lunch_board_controller.dart';
import 'fill_week_boxes_panel.dart';
import 'fill_week_done_panel.dart';
import 'fill_week_review_panel.dart';
import 'lunch_week_name.dart';

/// *Fill the week* (lunch-box ADR-0020): three steps for one child — pick
/// boxes, see the whole week, done — the one showing named at the top. The
/// screen only composes; every step is its controller's.
class FillWeekScreen extends StatelessWidget {
  const FillWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FillWeekController>();
    final step = controller.step;
    return NestScaffold(
      leading: backLeading(context),
      title: FillWeekCopy.title,
      subtitle: _subtitle(controller),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestStepsBar(
            count: FillWeekStep.values.length,
            index: step.index,
            label: FillWeekCopy.stepOf(step.index + 1),
          ),
          const SizedBox(height: NestSpace.lg),
          Expanded(
            child: NestAsyncView<LunchBoard>(
              state: controller.board,
              isEmpty: (board) => board.childWeek(controller.childId) == null,
              emptyBuilder: (_) => const NestEmptyView(
                icon: LucideIcons.userX,
                title: FillWeekCopy.noChildTitle,
                message: FillWeekCopy.noChildBody,
              ),
              onRetry: context.read<LunchBoardController>().retry,
              dataBuilder: (context, _) => AnimatedSwitcher(
                duration: NestMotion.of(context).standard,
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: switch (step) {
                    FillWeekStep.boxes => const FillWeekBoxesPanel(),
                    FillWeekStep.review => const FillWeekReviewPanel(),
                    FillWeekStep.done => const FillWeekDonePanel(),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "For Lwazi · This week": whose week, and which (lunch-box ADR-0019).
  static String? _subtitle(FillWeekController controller) {
    final board = controller.board;
    final child = controller.childWeek;
    if (board is! AsyncData<LunchBoard> || child == null) return null;
    return FillWeekCopy.forChild(
      child.child.member.displayName,
      LunchWeekName.ofBoard(board.value).label,
    );
  }
}
