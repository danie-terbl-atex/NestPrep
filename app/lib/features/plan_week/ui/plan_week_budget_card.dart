import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/state/lunch_budget_controller.dart';
import '../../lunch_box/ui/lunch_budget_flows.dart';

/// The household's weekly lunch budget in the brief — one budget for every
/// child together, what the basket is read against (lunch-box ADR-0012 §4) —
/// set or changed in place through budget mode's own sheet.
class PlanWeekBudgetCard extends StatelessWidget {
  const PlanWeekBudgetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final budget = context.watch<LunchBudgetController>();
    final week = switch (budget.week) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final amount = week?.budget?.money.displayShort;
    final failure = budget.actionFailure;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(PlanWeekCopy.budgetHeader, style: nest.text.caption),
          const SizedBox(height: NestSpace.xs),
          switch (budget.week) {
            AsyncLoading() => const NestSkeleton(height: NestSpace.xl),
            AsyncFailure(:final failure) => Text(
              AppCopy.failure(failure),
              style: nest.text.bodySecondary,
            ),
            AsyncData() => Text(
              amount == null
                  ? PlanWeekCopy.noBudget
                  : PlanWeekCopy.budgetIs(amount),
              style: amount == null ? nest.text.body : nest.text.title,
            ),
          },
          Text(PlanWeekCopy.budgetBody, style: nest.text.bodySecondary),
          if (failure != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: budget.dismissActionFailure,
            ),
          ],
          if (week != null) ...[
            const SizedBox(height: NestSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestButton(
                label: amount == null
                    ? PlanWeekCopy.setBudget
                    : PlanWeekCopy.changeBudget,
                icon: LucideIcons.piggyBank,
                variant: NestButtonVariant.ghost,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: () =>
                    LunchBudgetFlows.editBudget(context, week: week),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
