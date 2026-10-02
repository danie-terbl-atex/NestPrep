import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/state/lunch_budget_controller.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_child_names.dart';
import 'plan_week_search_row.dart';
import 'plan_week_step_actions.dart';

/// Step 3 (lunch-box ADR-0012): each idea searched at Checkers in turn, live
/// — waiting, searching, how many found and kept, and every product left out
/// with why — then the week is built from what was kept.
class PlanWeekStorePanel extends StatelessWidget {
  const PlanWeekStorePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<PlanWeekController>();
    final store = controller.store;
    final names = childNamesOf(controller.board);
    final searches = store.searches;
    final isSettled = store.isSettled;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(PlanWeekCopy.storeHeadline, style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.storeBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        for (final search in searches)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: PlanWeekSearchRow(
              key: ValueKey('search-${search.ideaId}'),
              search: search,
              childNames: names,
              onRetry: () => controller.retrySearch(search.ideaId),
            ),
          ),
        if (isSettled && !store.hasKept) ...[
          const SizedBox(height: NestSpace.md),
          const NestBanner(
            message: PlanWeekCopy.nothingKept,
            tone: NestBannerTone.warning,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        PlanWeekStepActions(
          nextKey: const ValueKey('plan-week-build'),
          label: PlanWeekCopy.buildAction,
          icon: LucideIcons.sparkles,
          isBusy: !isSettled,
          onNext: isSettled && store.hasKept ? () => _build(context) : null,
          onBack: controller.back,
        ),
      ],
    );
  }

  /// The week, read against the budget this phone last heard.
  static Future<void> _build(BuildContext context) {
    final budget = switch (context.read<LunchBudgetController>().week) {
      AsyncData(:final value) => value.budget?.money,
      _ => null,
    };
    return context.read<PlanWeekController>().buildWeek(budget: budget);
  }
}
