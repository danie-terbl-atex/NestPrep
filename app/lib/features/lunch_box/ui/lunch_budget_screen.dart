import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_planning_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../model/lunch_budget_week.dart';
import '../state/lunch_board_controller.dart';
import '../state/lunch_budget_controller.dart';
import 'lunch_basket_card.dart';
import 'lunch_budget_flows.dart';
import 'lunch_budget_locked.dart';
import 'lunch_budget_meter.dart';
import 'lunch_child_switcher.dart';
import 'lunch_swap_row.dart';

/// Budget mode (lunch-box ADR-0007, ADR-0012 §4): the household's week
/// against its budget, the basket behind it in whole packs, and cheaper swaps
/// for the child whose week is open. Premium — a free household sees what it would get instead.
class LunchBudgetScreen extends StatelessWidget {
  const LunchBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<LunchBudgetController>();
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    final failure = budget.actionFailure;
    return NestScaffold(
      title: LunchBudgetCopy.title,
      subtitle: LunchBudgetCopy.subtitle,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: budget.dismissActionFailure,
              ),
            ),
          Expanded(
            child: !isPremium
                ? const LunchBudgetLocked()
                : NestAsyncView<LunchBudgetWeek>(
                    state: budget.week,
                    // The meter and the way to prices are the view in every
                    // state, so it is never swapped for an empty one.
                    isEmpty: (_) => false,
                    onRetry: budget.retry,
                    emptyBuilder: (_) => const SizedBox.shrink(),
                    dataBuilder: (context, week) => _BudgetBody(week: week),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BudgetBody extends StatelessWidget {
  const _BudgetBody({required this.week});

  final LunchBudgetWeek week;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final view = context.watch<HouseholdView>();
    final canEdit = view.permissions.canEdit(HouseholdArea.lunch);
    final lunch = context.watch<LunchBoardController>();
    final board = week.board;
    final childWeek =
        board.childWeek(lunch.selectedChildId ?? '') ??
        board.children.firstOrNull;
    final unpriced = week.cost.unpricedNames.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(
          child: LunchBudgetMeter(
            week: week,
            onEdit: canEdit
                ? () => LunchBudgetFlows.editBudget(context, week: week)
                : null,
          ),
        ),
        if (unpriced > 0) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(message: LunchBudgetCopy.unpriced(unpriced)),
          // Under the banner rather than inside it: at large text the
          // banner's own action leaves its sentence no room.
          if (canEdit)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestButton(
                label: LunchBudgetCopy.priceThem,
                icon: LucideIcons.tag,
                variant: NestButtonVariant.ghost,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: () => context.push(
                  LunchPlanningRoute.pricesPathFor(view.household.id),
                ),
              ),
            ),
        ],
        const SizedBox(height: NestSpace.md),
        NestRiseIn(index: 1, child: LunchBasketCard(basket: week.cost.basket)),
        if (childWeek != null) ...[
          const SizedBox(height: NestSpace.xl),
          LunchChildSwitcher(
            children: board.children,
            selectedChildId: childWeek.childId,
            onSelect: lunch.selectChild,
          ),
          const SizedBox(height: NestSpace.sm),
          NestSectionHeader(
            title: LunchBudgetCopy.swapsFor(childWeek.child.member.displayName),
          ),
          if (week.swapsFor(childWeek.childId) case final swaps
              when swaps.isEmpty)
            Text(LunchBudgetCopy.noSwaps, style: nest.text.bodySecondary),
          for (final swap in week.swapsFor(childWeek.childId))
            LunchSwapRow(
              key: ValueKey('${swap.from.id}-${swap.to.item.id}'),
              swap: swap,
              onSwap: canEdit
                  ? () => LunchBudgetFlows.swap(
                      context,
                      childId: childWeek.childId,
                      swap: swap,
                    )
                  : null,
            ),
        ],
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: LunchBudgetCopy.allPrices,
          icon: LucideIcons.tag,
          variant: NestButtonVariant.outline,
          onPressed: () =>
              context.push(LunchPlanningRoute.pricesPathFor(view.household.id)),
        ),
      ],
    );
  }
}
