import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_budget_card.dart';
import 'plan_week_child_rules_card.dart';
import 'plan_week_shop_card.dart';
import 'plan_week_step_actions.dart';

/// Step 1 (lunch-box ADR-0012): whose lunches, what NestPrep will keep out
/// of each child's box and what they like, the shop, and the household's
/// budget — then the ideas.
class PlanWeekBriefPanel extends StatelessWidget {
  const PlanWeekBriefPanel({required this.board, super.key});

  final LunchBoard board;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<PlanWeekController>();
    final chosen = controller.childIds;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(PlanWeekCopy.briefHeadline, style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.briefBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: PlanWeekCopy.lunchesFor),
        const SizedBox(height: NestSpace.sm),
        if (board.children.isEmpty)
          Text(PlanWeekCopy.noChildren, style: nest.text.bodySecondary)
        else
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final child in board.children)
                NestChip(
                  key: ValueKey('plan-child-${child.childId}'),
                  label: child.child.member.displayName,
                  isSelected: chosen.contains(child.childId),
                  icon: chosen.contains(child.childId)
                      ? LucideIcons.check
                      : LucideIcons.plus,
                  onTap: () => controller.toggleChild(child.childId),
                ),
            ],
          ),
        for (final child in board.children)
          if (chosen.contains(child.childId)) ...[
            const SizedBox(height: NestSpace.md),
            PlanWeekChildRulesCard(
              key: ValueKey('plan-rules-${child.childId}'),
              child: child.child,
            ),
          ],
        const SizedBox(height: NestSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.lock,
              size: NestSize.iconSmall,
              color: nest.colors.inkTertiary,
            ),
            const SizedBox(width: NestSpace.sm),
            Expanded(
              child: Text(PlanWeekCopy.aiNeverSees, style: nest.text.caption),
            ),
          ],
        ),
        const SizedBox(height: NestSpace.xl),
        const PlanWeekShopCard(),
        const SizedBox(height: NestSpace.md),
        const PlanWeekBudgetCard(),
        const SizedBox(height: NestSpace.xl),
        PlanWeekStepActions(
          nextKey: const ValueKey('plan-week-ideas'),
          label: PlanWeekCopy.draftAction,
          icon: LucideIcons.sparkles,
          onNext: chosen.isEmpty ? null : controller.draftIdeas,
        ),
      ],
    );
  }
}
