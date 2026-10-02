import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/lunch_board.dart';
import '../model/lunch_day.dart';
import '../state/lunch_board_controller.dart';
import 'art/lunch_photo.dart';
import 'lunch_day_detail_screen.dart';
import 'lunch_flows.dart';

/// The day on show as the brand's photo card (design-system ADR-0008,
/// ADR-0010): the box, whose it is and what is in it, opening into the day
/// with its photo, and the one button that packs the rest of the week.
class LunchHero extends StatelessWidget {
  const LunchHero({
    required this.board,
    required this.childWeek,
    required this.day,
    required this.canEdit,
    super.key,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;
  final LunchDay day;
  final bool canEdit;

  static Object heroTagFor(LunchChildWeek childWeek, LunchDay day) =>
      'lunch-${childWeek.childId}-${day.date.iso}';

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<LunchBoardController>();
    final name = childWeek.child.member.displayName;
    final picks = [for (final (_, pick) in day.box.filled) pick.name];
    final isFull = childWeek.filledDays == childWeek.days.length;
    final tag = heroTagFor(childWeek, day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestPhotoCard(
          heroTag: tag,
          photo: LunchPhoto(
            box: day.box,
            childId: childWeek.childId,
            date: day.date,
          ),
          actionLabel: picks.isEmpty
              ? LunchCopy.planThisLunch
              : LunchCopy.viewLunch,
          actionIcon: LucideIcons.arrowUpRight,
          semanticsLabel:
              '${LunchCopy.dayFor(NestDates.weekdayName(day.date), name)}. '
              '${picks.isEmpty ? LunchCopy.nothingPackedYet : picks.join(', ')}',
          onTap: () => Navigator.of(context).push(
            NestPhotoRoute<void>(
              motion: NestMotion.of(context),
              builder: (_) => LunchDayDetailScreen(
                heroTag: tag,
                childId: childWeek.childId,
                date: day.date,
                canEdit: canEdit,
              ),
            ),
          ),
        ),
        const SizedBox(height: NestSpace.md),
        NestEyebrow(
          LunchCopy.dayFor(NestDates.relative(day.date, board.today), name),
        ),
        const SizedBox(height: NestSpace.xs),
        Text(
          picks.isEmpty ? LunchCopy.nothingPackedYet : picks.first,
          style: nest.text.headline,
        ),
        if (picks.length > 1) ...[
          const SizedBox(height: NestSpace.xs),
          Text(picks.skip(1).join(', '), style: nest.text.bodySecondary),
        ],
        if (canEdit) ...[
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: LunchCopy.fillWeek,
            icon: LucideIcons.sparkles,
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
          NestButton(
            label: LunchCopy.goToBoxCount(childWeek.favourites.length),
            icon: LucideIcons.heart,
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
    );
  }
}
