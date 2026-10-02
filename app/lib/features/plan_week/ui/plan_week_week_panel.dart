import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/state/lunch_budget_controller.dart';
import '../model/shop_week.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_basket_section.dart';
import 'plan_week_child_card.dart';
import 'plan_week_step_actions.dart';
import 'plan_week_week_header.dart';
import 'plan_week_working_panel.dart';

/// Step 4 (lunch-box ADR-0012): each child's week from what the shop had —
/// what was packed already, quiet; what is new, a tap from being swapped —
/// the basket in whole packs against the household's budget, then *Use this
/// week*.
class PlanWeekWeekPanel extends StatelessWidget {
  const PlanWeekWeekPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    return switch (controller.shop.state) {
      AsyncLoading() => const PlanWeekWorkingPanel(
        title: PlanWeekCopy.buildingTitle,
        line: PlanWeekCopy.buildingLine,
      ),
      AsyncFailure(:final failure) => NestErrorView(
        message: AppCopy.failure(failure),
        retryLabel: AppCopy.retry,
        onRetry: () => _rebuild(context),
        secondaryLabel: PlanWeekCopy.back,
        onSecondary: controller.back,
      ),
      AsyncData(:final value) => _Week(plan: value),
    };
  }

  static Future<void> _rebuild(BuildContext context) {
    final budget = switch (context.read<LunchBudgetController>().week) {
      AsyncData(:final value) => value.budget?.money,
      _ => null,
    };
    return context.read<PlanWeekController>().buildWeek(budget: budget);
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.plan});

  final ShopWeek plan;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    final shop = controller.shop;
    final failure = shop.failure;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        PlanWeekWeekHeader(plan: plan),
        if (plan.isEmpty) ...[
          const SizedBox(height: NestSpace.lg),
          const NestEmptyView(
            icon: Icons.bento_outlined,
            title: PlanWeekCopy.nothingNew,
            message: PlanWeekCopy.nothingNewBody,
          ),
        ] else ...[
          for (final child in plan.children) ...[
            const SizedBox(height: NestSpace.md),
            PlanWeekChildCard(
              key: ValueKey('plan-child-week-${child.childId}'),
              plan: plan,
              child: child,
              isEditable: !shop.isSaving,
            ),
          ],
          const SizedBox(height: NestSpace.md),
          PlanWeekBasketSection(plan: plan),
        ],
        if (failure != null) ...[
          const SizedBox(height: NestSpace.lg),
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: shop.dismissFailure,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        PlanWeekStepActions(
          nextKey: const ValueKey('plan-week-use'),
          label: PlanWeekCopy.useAction,
          icon: Icons.check_rounded,
          isBusy: shop.isSaving,
          onNext: plan.isEmpty ? null : controller.use,
          onBack: shop.isSaving ? null : controller.back,
        ),
      ],
    );
  }
}
