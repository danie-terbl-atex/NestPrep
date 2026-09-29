import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/lunch_board.dart';
import '../model/lunch_day.dart';
import '../state/lunch_board_controller.dart';
import 'art/lunch_box_art.dart';
import 'lunch_flows.dart';

/// The top of the lunch screen: the next box that matters — today's, or the
/// first of a week still to come — drawn, and the one button that packs the
/// rest of the week (lunch-box ADR-0003, ADR-0004).
class LunchHeroCard extends StatelessWidget {
  const LunchHeroCard({
    required this.board,
    required this.childWeek,
    required this.canEdit,
    super.key,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<LunchBoardController>();
    final day = board.focusDayOf(childWeek);
    final member = childWeek.child.member;
    final isFull = childWeek.filledDays == childWeek.days.length;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestAvatar(name: member.displayName, color: member.color),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LunchCopy.packingFor(member.displayName),
                      style: nest.text.caption,
                    ),
                    Text(_headline(day), style: nest.text.title),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          Center(child: LunchBoxArt(box: day.box)),
          const SizedBox(height: NestSpace.md),
          Text(
            day.box.isEmpty
                ? LunchCopy.nothingPackedYet
                : LunchCopy.packedCount(day.box.filledCount),
            textAlign: TextAlign.center,
            style: nest.text.bodySecondary,
          ),
          if (canEdit) ...[
            const SizedBox(height: NestSpace.lg),
            NestButton(
              label: LunchCopy.fillWeek,
              icon: Icons.auto_awesome_rounded,
              isLoading: controller.edit.isFilling,
              onPressed: isFull
                  ? null
                  : () => LunchFlows.fillWeek(context, childWeek: childWeek),
            ),
            const SizedBox(height: NestSpace.sm),
            Text(
              isFull ? LunchCopy.weekIsFull : LunchCopy.fillWeekHint,
              textAlign: TextAlign.center,
              style: nest.text.caption,
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: LunchCopy.goToBoxCount(childWeek.favourites.length),
              icon: Icons.favorite_border_rounded,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              onPressed: () => LunchFlows.packFavourite(
                context,
                childWeek: childWeek,
                day: day,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _headline(LunchDay day) {
    if (day.isToday) return LunchCopy.todaysBox;
    if (day.date == board.today.addDays(1)) return LunchCopy.tomorrowsBox;
    return LunchCopy.boxFor(NestDates.weekdayName(day.date));
  }
}
