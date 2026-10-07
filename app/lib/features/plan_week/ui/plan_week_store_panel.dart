import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_idea.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_working_panel.dart';

/// Step 3 (lunch-box ADR-0012): each idea searched at Checkers in turn,
/// counted while it works; the week is built from what was kept as soon as
/// the run settles. Only a run that kept nothing stops here, and says so.
class PlanWeekStorePanel extends StatelessWidget {
  const PlanWeekStorePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    final store = controller.store;
    if (store.isSettled && !store.hasKept) {
      return NestEmptyView(
        key: const ValueKey('plan-week-nothing-kept'),
        icon: LucideIcons.searchX,
        title: PlanWeekCopy.nothingKeptTitle,
        message: PlanWeekCopy.nothingKept,
        actionLabel: PlanWeekCopy.back,
        onAction: controller.back,
      );
    }
    final searched = [
      for (final search in store.searches)
        if (search.idea.origin != IdeaOrigin.aisle) search,
    ];
    return PlanWeekWorkingPanel(
      key: const ValueKey('plan-week-shopping'),
      title: PlanWeekCopy.storeTitle,
      line: PlanWeekCopy.storeLine,
      progress: searched.isEmpty
          ? null
          : PlanWeekCopy.storeProgress(
              searched.where((search) => search.isSettled).length,
              searched.length,
            ),
    );
  }
}
