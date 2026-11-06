import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/shop_week.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_basket_section.dart';
import 'plan_week_child_card.dart';
import 'plan_week_week_header.dart';
import 'plan_week_week_name.dart';
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
      // The week is the model's to build: the phone builds one only once it
      // has said it cannot help, and that is never a wait.
      AsyncLoading() => PlanWeekWorkingPanel(
        title: PlanWeekCopy.buildingTitle,
        line: PlanWeekCopy.buildingLine(controller.retailer.shop),
        twig: NestTwigPose.planning,
      ),
      AsyncFailure(:final failure) => NestErrorView(
        message: AppCopy.failure(failure),
        retryLabel: AppCopy.retry,
        onRetry: controller.buildWeek,
        secondaryLabel: PlanWeekCopy.back,
        onSecondary: controller.back,
      ),
      AsyncData(:final value) => _Week(plan: value),
    };
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
    final weekName = planWeekName(controller);
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        PlanWeekWeekHeader(plan: plan, weekName: weekName),
        if (plan.isEmpty) ...[
          const SizedBox(height: NestSpace.lg),
          if (plan.daysLeft.isEmpty)
            const NestEmptyView(
              icon: LucideIcons.calendarX,
              title: PlanWeekCopy.noDaysLeftTitle,
              message: PlanWeekCopy.noDaysLeft,
            )
          else
            NestEmptyView(
              icon: LucideIcons.sandwich,
              title: PlanWeekCopy.nothingNew(weekName.inSentence),
              message: PlanWeekAgainCopy.nothingNewBody(
                controller.retailer.shop,
              ),
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
          PlanWeekBasketSection(plan: plan, weekName: weekName),
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
        NestStepActions(
          // A week with nothing new leads back to the brief, never to a
          // button that cannot be pressed (lunch-box ADR-0027).
          nextKey: ValueKey(
            plan.isEmpty ? 'plan-week-to-brief' : 'plan-week-use',
          ),
          nextLabel: plan.isEmpty
              ? PlanWeekAgainCopy.backToBrief
              : PlanWeekCopy.useAction,
          nextIcon: plan.isEmpty ? LucideIcons.arrowLeft : LucideIcons.check,
          isBusy: shop.isSaving,
          onNext: plan.isEmpty ? controller.startOver : controller.use,
          backLabel: PlanWeekCopy.back,
          onBack: shop.isSaving ? null : controller.back,
        ),
      ],
    );
  }
}
