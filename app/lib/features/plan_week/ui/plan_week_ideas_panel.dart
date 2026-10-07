import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/state/lunch_budget_controller.dart';
import '../state/plan_week_controller.dart';
import '../state/plan_week_ideas.dart';
import 'plan_week_child_names.dart';
import 'plan_week_idea_row.dart';
import 'plan_week_idea_sheet.dart';
import 'plan_week_step_actions.dart';
import 'plan_week_working_panel.dart';

/// Step 2 (lunch-box ADR-0012): the lunchbox aisle's shelves (ADR-0013) and
/// the ideas to look for at the shop, by compartment, each with why and for
/// whom — and, struck through, what NestPrep left out for a child and why.
/// Remove any, add your own, then go to the shop.
class PlanWeekIdeasPanel extends StatelessWidget {
  const PlanWeekIdeasPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    final aisle = controller.aisle;
    return switch (controller.ideas.state) {
      AsyncLoading() when aisle.isReading => PlanWeekWorkingPanel(
        key: const ValueKey('plan-week-aisle-reading'),
        title: PlanWeekCopy.aisleTitle,
        line: PlanWeekCopy.aisleLine,
        progress: aisle.total == 0
            ? null
            : PlanWeekCopy.aisleProgress(aisle.shelvesRead, aisle.total),
      ),
      AsyncLoading() => const PlanWeekWorkingPanel(
        title: PlanWeekCopy.draftingTitle,
        line: PlanWeekCopy.draftingLine,
      ),
      AsyncFailure(:final failure) => NestErrorView(
        message: AppCopy.failure(failure),
        retryLabel: AppCopy.retry,
        onRetry: controller.draftIdeas,
        secondaryLabel: PlanWeekCopy.back,
        onSecondary: controller.back,
      ),
      AsyncData(:final value) => _IdeaList(list: value),
    };
  }
}

class _IdeaList extends StatelessWidget {
  const _IdeaList({required this.list});

  final IdeaList list;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<PlanWeekController>();
    final names = childNamesOf(controller.board);
    final active = controller.ideas.active.length;
    final reason = list.reason;
    final unread = controller.aisle.unread;
    final shelves = {
      for (final shelf in controller.aisle.shelves)
        shelf.ideaId: shelf.kept.length,
    };
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(PlanWeekCopy.ideasHeadline, style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.ideasBody, style: nest.text.bodySecondary),
        if (reason != null) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(message: PlanWeekCopy.fallbackIdeas(reason)),
        ],
        if (unread > 0) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(
            message: PlanWeekCopy.aisleUnread(unread),
            tone: NestBannerTone.warning,
          ),
        ],
        for (final slot in LunchSlot.values)
          if (list.ideas.where((idea) => idea.slot == slot).toList()
              case final ideas when ideas.isNotEmpty) ...[
            const SizedBox(height: NestSpace.lg),
            NestSectionHeader(title: LunchCopy.slotName(slot)),
            for (final idea in ideas)
              PlanWeekIdeaRow(
                key: ValueKey('idea-${idea.id}'),
                idea: idea,
                shelfKept: shelves[idea.id],
                childNames: names,
                onRemove: () => controller.ideas.remove(idea.id),
              ),
          ],
        if (active == 0) ...[
          const SizedBox(height: NestSpace.lg),
          const NestEmptyView(
            icon: LucideIcons.lightbulb,
            title: PlanWeekCopy.noIdeas,
            message: PlanWeekCopy.noIdeasBody,
          ),
        ],
        const SizedBox(height: NestSpace.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: NestButton(
            key: const ValueKey('plan-week-add-idea'),
            label: PlanWeekCopy.addIdea,
            icon: LucideIcons.plus,
            variant: NestButtonVariant.outline,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: () => _addIdea(context, controller),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        PlanWeekStepActions(
          nextKey: const ValueKey('plan-week-search'),
          label: PlanWeekCopy.searchAction(active),
          icon: LucideIcons.store,
          onNext: active == 0 ? null : () => _search(context, controller),
          onBack: controller.back,
        ),
      ],
    );
  }

  static Future<void> _addIdea(
    BuildContext context,
    PlanWeekController controller,
  ) async {
    final added = await showPlanWeekIdeaSheet(
      context,
      slots: controller.packing.slots,
    );
    if (added == null) return;
    controller.addOwnIdea(added.slot, added.text);
  }

  /// To the shop and on to the week, read against the budget this phone
  /// last heard.
  static Future<void> _search(
    BuildContext context,
    PlanWeekController controller,
  ) => controller.searchStore(
    budget: switch (context.read<LunchBudgetController>().week) {
      AsyncData(:final value) => value.budget?.money,
      _ => null,
    },
  );
}
