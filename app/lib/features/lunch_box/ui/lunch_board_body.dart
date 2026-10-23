import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../family_profiles/ui/food_rules_summary.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import '../model/lunch_board.dart';
import '../state/lunch_board_controller.dart';
import 'lunch_child_switcher.dart';
import 'lunch_day_actions.dart';
import 'lunch_day_pills.dart';
import 'lunch_hero.dart';
import 'lunch_tool_grid.dart';
import 'lunch_week_days.dart';
import 'lunch_week_name.dart';
import 'lunch_week_planner.dart';

/// One child's week, organised by scope, narrowest first (lunch-box
/// ADR-0022): whose it is and their food rules; the day on show, as pills and
/// a photo card, with what can be done to that day; the whole week under its
/// name — its planner, then the five days in full; and last, the lunch tools.
/// The days are the empty state too — each empty compartment is a way in
/// (`FE-08`).
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
        NestRiseIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (board.children.length > 1) ...[
                TourAnchor(
                  target: TourTarget.lunchChildSwitcher,
                  child: LunchChildSwitcher(
                    children: board.children,
                    selectedChildId: childWeek.childId,
                    onSelect: controller.selectChild,
                  ),
                ),
                const SizedBox(height: NestSpace.md),
              ],
              // The rules are the child's, read before anything is planned.
              FoodRulesSummary(rules: childWeek.child.foodRules),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        NestSectionHeader(title: NestDates.relative(day.date, board.today)),
        const SizedBox(height: NestSpace.sm),
        NestRiseIn(
          child: TourAnchor(
            target: TourTarget.lunchDayPills,
            child: LunchDayPills(
              days: childWeek.days,
              selected: day,
              onSelect: (day) => setState(() => _shown = day.date),
            ),
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        NestRiseIn(
          index: 1,
          child: TourAnchor(
            target: TourTarget.lunchDay,
            child: LunchHero(
              key: ValueKey('hero-${childWeek.childId}'),
              board: board,
              childWeek: childWeek,
              day: day,
              canEdit: canEdit,
            ),
          ),
        ),
        if (canEdit) LunchDayActions(childWeek: childWeek, day: day),
        const SizedBox(height: NestSpace.xxxl),
        NestSectionHeader(title: LunchWeekName.ofBoard(board).label),
        const SizedBox(height: NestSpace.sm),
        if (canEdit)
          NestRiseIn(
            index: 2,
            child: TourAnchor(
              target: TourTarget.lunchPlanner,
              child: LunchWeekPlanner(board: board, childWeek: childWeek),
            ),
          ),
        LunchWeekDays(board: board, childWeek: childWeek, canEdit: canEdit),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: LunchCopy.toolsTitle),
        const SizedBox(height: NestSpace.sm),
        TourAnchor(
          target: TourTarget.lunchTools,
          child: LunchToolGrid(canEdit: canEdit),
        ),
      ],
    );
  }
}
