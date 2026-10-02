import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../family_profiles/ui/food_rules_summary.dart';
import '../../household/model/household_view.dart';
import '../../plan_week/ui/plan_week_entry_card.dart';
import '../model/lunch_board.dart';
import '../state/lunch_board_controller.dart';
import 'lunch_auto_fill_note.dart';
import 'lunch_child_switcher.dart';
import 'lunch_day_card.dart';
import 'lunch_day_pills.dart';
import 'lunch_flows.dart';
import 'lunch_hero.dart';
import 'lunch_planning_tools.dart';

/// One child's week, top to bottom: whose it is, the five days as pills, the
/// day on show as a photo card with the button that packs the rest, the
/// tools, their food rules, and the five days in full. The days are the empty
/// state too — each empty compartment is a way in (`FE-08`).
///
/// It arrives once, top down, and settles (design-system ADR-0002).
class LunchBoardBody extends StatefulWidget {
  const LunchBoardBody({required this.board, required this.canEdit, super.key});

  final LunchBoard board;
  final bool canEdit;

  @override
  State<LunchBoardBody> createState() => _LunchBoardBodyState();
}

class _LunchBoardBodyState extends State<LunchBoardBody> {
  CalendarDate? _shown;
  String? _shownFor;

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final canEdit = widget.canEdit;
    final controller = context.watch<LunchBoardController>();
    final childWeek =
        board.childWeek(controller.selectedChildId ?? '') ??
        board.children.first;
    final householdId = context.read<HouseholdView>().household.id;
    final scope = '${childWeek.childId}-${board.week.key}';
    if (_shownFor != scope) {
      _shownFor = scope;
      _shown = board.focusDayOf(childWeek).date;
    }
    final day =
        childWeek.days.where((day) => day.date == _shown).firstOrNull ??
        board.focusDayOf(childWeek);
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
        if (board.children.length > 1) ...[
          NestRiseIn(
            child: LunchChildSwitcher(
              children: board.children,
              selectedChildId: childWeek.childId,
              onSelect: controller.selectChild,
            ),
          ),
          const SizedBox(height: NestSpace.md),
        ],
        NestRiseIn(
          child: LunchDayPills(
            days: childWeek.days,
            selected: day,
            onSelect: (day) => setState(() => _shown = day.date),
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        NestRiseIn(
          index: 1,
          child: LunchHero(
            key: ValueKey('hero-${childWeek.childId}'),
            board: board,
            childWeek: childWeek,
            day: day,
            canEdit: canEdit,
          ),
        ),
        const SizedBox(height: NestSpace.md),
        // plan my week with AI — the week in one tap (lunch-box ADR-0011).
        PlanWeekEntryCard(board: board, canEdit: canEdit),
        const SizedBox(height: NestSpace.md),
        NestRiseIn(
          index: 2,
          child: Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestButton(
                label: LunchCopy.openPrep,
                icon: LucideIcons.soup,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: () => LunchFlows.openPrep(
                  context,
                  path: LunchRoute.prepPathFor(householdId),
                ),
              ),
              if (canEdit) ...[
                NestButton(
                  label: LunchCopy.openLibrary,
                  icon: LucideIcons.bookOpen,
                  variant: NestButtonVariant.tonal,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: () =>
                      context.push(LunchRoute.libraryPathFor(householdId)),
                ),
                // Sharing the week is for the people who plan it
                // (lunch-box ADR-0005).
                NestButton(
                  label: LunchShareCopy.openShare,
                  icon: LucideIcons.share,
                  variant: NestButtonVariant.tonal,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: () =>
                      context.push(LunchRoute.sharePathFor(householdId)),
                ),
              ],
            ],
          ),
        ),
        // lunch-box V2 — pantry, budget, kid picks (ADR-0006 to ADR-0008).
        LunchPlanningTools(
          board: board,
          childWeek: childWeek,
          canEdit: canEdit,
        ),
        const SizedBox(height: NestSpace.md),
        FoodRulesSummary(rules: childWeek.child.foodRules),
        if (childWeek.unsafeCount > 0)
          const Padding(
            padding: EdgeInsets.only(top: NestSpace.sm),
            child: NestBanner(
              message: LunchCopy.weekHasUnsafe,
              tone: NestBannerTone.danger,
            ),
          ),
        const LunchAutoFillNote(),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: LunchCopy.thisWeek),
        const SizedBox(height: NestSpace.sm),
        for (final (index, day) in childWeek.days.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestRiseIn(
              index: index + 3,
              child: LunchDayCard(
                key: ValueKey('${childWeek.childId}-${day.date.iso}'),
                board: board,
                childWeek: childWeek,
                day: day,
                canEdit: canEdit,
              ),
            ),
          ),
      ],
    );
  }
}
