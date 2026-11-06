import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_budget_card.dart';
import 'plan_week_child_rules_card.dart';
import 'plan_week_days_left_note.dart';
import 'plan_week_list_cart_card.dart';
import 'plan_week_packing_section.dart';
import 'plan_week_shop_card.dart';

/// Step 1 (lunch-box ADR-0012): which of the week's school days are left,
/// whose lunches, what NestPrep will keep out
/// of each child's box and what they like, which compartments to fill and
/// how the parent likes to pack, the shop, and the household's budget — then
/// the ideas.
class PlanWeekBriefPanel extends StatelessWidget {
  const PlanWeekBriefPanel({required this.board, super.key});

  final LunchBoard board;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<PlanWeekController>();
    final chosen = controller.childIds;
    final daysLeft = board.week.daysLeftAfter(board.today);
    final mayPushToCart = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.groceries,
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(PlanWeekCopy.briefHeadline, style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.briefBody, style: nest.text.bodySecondary),
        if (daysLeft.length < board.week.schoolDays.length) ...[
          const SizedBox(height: NestSpace.md),
          PlanWeekDaysLeftNote(week: board.week, daysLeft: daysLeft),
        ],
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
        const PlanWeekPackingSection(),
        const SizedBox(height: NestSpace.xl),
        const PlanWeekShopCard(),
        if (mayPushToCart) ...[
          const SizedBox(height: NestSpace.md),
          const PlanWeekListCartCard(),
        ],
        const SizedBox(height: NestSpace.md),
        const PlanWeekBudgetCard(),
        const SizedBox(height: NestSpace.xl),
        NestStepActions(
          nextKey: const ValueKey('plan-week-ideas'),
          nextLabel: PlanWeekCopy.draftAction,
          nextIcon: LucideIcons.sparkles,
          onNext: chosen.isEmpty || daysLeft.isEmpty
              ? null
              : controller.draftIdeas,
        ),
      ],
    );
  }
}
