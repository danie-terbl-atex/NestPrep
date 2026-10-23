import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_board.dart';
import 'lunch_auto_fill_note.dart';
import 'lunch_day_card.dart';

/// The week at a glance, under the week's planner (lunch-box ADR-0022): a
/// warning when something packed is no longer safe, what *Fill the week* just
/// did, then the five days in full — whose empty compartments are the way
/// in (`FE-08`). Everybody who may see lunches sees these.
class LunchWeekDays extends StatelessWidget {
  const LunchWeekDays({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
