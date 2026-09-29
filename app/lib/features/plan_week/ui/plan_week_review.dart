import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/planned_week.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_child_card.dart';
import 'plan_week_dinners_card.dart';
import 'plan_week_review_header.dart';

/// *Your week, planned* (lunch-box ADR-0011): who made it, each child's week
/// with what is new standing out from what was packed already, the dinners,
/// and the one button that uses it. Anything new can be swapped first;
/// nothing is written until *Use this plan*.
class PlanWeekReview extends StatelessWidget {
  const PlanWeekReview({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    final planned = controller.planned;
    if (planned == null) return const SizedBox.shrink();
    final isSaving = controller.step == PlanWeekStep.saving;
    final failure = controller.failure;

    if (planned.isEmpty) {
      return NestEmptyView(
        icon: Icons.event_available_outlined,
        title: PlanWeekCopy.nothingToAdd,
        message: PlanWeekCopy.nothingToAddBody,
        actionLabel: PlanWeekCopy.startOver,
        onAction: controller.startOver,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: NestSpace.xl),
            children: [
              NestRiseIn(child: PlanWeekReviewHeader(planned: planned)),
              if (planned.children.isNotEmpty) ...[
                const SizedBox(height: NestSpace.xl),
                const NestSectionHeader(title: PlanWeekCopy.lunchesHeader),
                const SizedBox(height: NestSpace.sm),
                for (final (index, child) in planned.children.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NestSpace.md),
                    child: NestRiseIn(
                      index: index + 1,
                      child: PlanWeekChildCard(
                        key: ValueKey('plan-child-card-${child.childId}'),
                        planned: child,
                        week: planned.week,
                        isEditable: !isSaving,
                      ),
                    ),
                  ),
              ],
              if (planned.dinnersIncluded) ...[
                const SizedBox(height: NestSpace.md),
                const NestSectionHeader(title: PlanWeekCopy.dinnersHeader),
                const SizedBox(height: NestSpace.sm),
                NestRiseIn(
                  index: planned.children.length + 1,
                  child: PlanWeekDinnersCard(
                    planned: planned,
                    isEditable: !isSaving,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissFailure,
            ),
          ),
        _Actions(planned: planned, isSaving: isSaving),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.planned, required this.isSaving});

  final PlannedWeek planned;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PlanWeekController>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: NestSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NestButton(
              key: const ValueKey('plan-week-use'),
              label: isSaving ? PlanWeekCopy.saving : PlanWeekCopy.useAction,
              icon: Icons.check_rounded,
              isLoading: isSaving,
              onPressed: isSaving || planned.isEmpty ? null : controller.use,
            ),
            const SizedBox(height: NestSpace.xs),
            NestButton(
              label: PlanWeekCopy.startOver,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              onPressed: isSaving ? null : controller.startOver,
            ),
          ],
        ),
      ),
    );
  }
}
