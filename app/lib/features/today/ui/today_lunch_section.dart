import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/state/lunch_board_controller.dart';
import '../../lunch_box/ui/art/lunch_photo.dart';
import 'today_async.dart';
import 'today_section.dart';

/// The next box that matters for each child, as a photo card that opens
/// the lunch tab.
class TodayLunchSection extends StatelessWidget {
  const TodayLunchSection({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchBoardController>();
    return TodaySection(
      eyebrow: TodayCopy.lunchEyebrow,
      child: TodayAsync<LunchBoard>(
        state: controller.board,
        builder: (context, board) => Column(
          children: [
            for (final childWeek in board.children)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.lg),
                child: _ChildLunch(
                  board: board,
                  childWeek: childWeek,
                  onOpen: onOpen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChildLunch extends StatelessWidget {
  const _ChildLunch({
    required this.board,
    required this.childWeek,
    required this.onOpen,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final day = board.focusDayOf(childWeek);
    final name = childWeek.child.member.displayName;
    final picks = [for (final (_, pick) in day.box.filled) pick.name];
    final title = picks.isEmpty ? TodayCopy.nothingPacked : picks.join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NestPhotoCard(
          heroTag: 'today-lunch-${childWeek.childId}',
          photo: LunchPhoto(box: day.box),
          actionLabel: picks.isEmpty
              ? TodayCopy.planLunch
              : TodayCopy.viewLunch,
          actionIcon: LucideIcons.arrowUpRight,
          semanticsLabel: '$name. $title',
          onTap: onOpen,
        ),
        const SizedBox(height: NestSpace.md),
        NestEyebrow(
          '${NestDates.relative(day.date, board.today)} · '
          '${TodayCopy.lunchFor(name)}',
        ),
        const SizedBox(height: NestSpace.xs),
        Text(title, style: nest.text.screenTitle),
      ],
    );
  }
}
