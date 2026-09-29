import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/ui/food_rules_summary.dart';
import '../../household/model/household_view.dart';
import '../model/lunch_board.dart';
import '../state/lunch_board_controller.dart';
import 'lunch_auto_fill_note.dart';
import 'lunch_child_switcher.dart';
import 'lunch_day_card.dart';
import 'lunch_flows.dart';
import 'lunch_hero_card.dart';

/// One child's week, top to bottom: whose it is, the next box drawn with the
/// button that packs the rest, their food rules, and the five days. The days
/// are the empty state too — each empty compartment is a way in (`FE-08`).
///
/// It arrives once, top down, and settles (design-system ADR-0002).
class LunchBoardBody extends StatelessWidget {
  const LunchBoardBody({required this.board, required this.canEdit, super.key});

  final LunchBoard board;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchBoardController>();
    final childWeek =
        board.childWeek(controller.selectedChildId ?? '') ??
        board.children.first;
    final householdId = context.read<HouseholdView>().household.id;
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
          index: 1,
          child: LunchHeroCard(
            key: ValueKey('hero-${childWeek.childId}'),
            board: board,
            childWeek: childWeek,
            canEdit: canEdit,
          ),
        ),
        const SizedBox(height: NestSpace.md),
        NestRiseIn(
          index: 2,
          child: Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestButton(
                label: LunchCopy.openPrep,
                icon: Icons.soup_kitchen_outlined,
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
                  icon: Icons.menu_book_outlined,
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
                  icon: Icons.ios_share_rounded,
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
        const SizedBox(height: NestSpace.md),
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
