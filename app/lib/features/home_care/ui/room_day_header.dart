import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/routine/room_day.dart';
import 'room_kind_look.dart';
import 'step_progress_bar.dart';

/// A room on a day, at the top of its card: its icon and name, how far
/// through, and — in words as well as green — when it is all done
/// (home-care ADR-0004, `FE-13`).
class RoomDayHeader extends StatelessWidget {
  const RoomDayHeader({required this.day, this.isLarge = false, super.key});

  final RoomDay day;

  /// The helper's card is bigger than the parent's overview line.
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final room = day.room;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NestIconTile(
              icon: room?.kind.icon ?? LucideIcons.doorClosed,
              tint: room?.kind.tint ?? NestTileTint.accent,
              size: isLarge ? NestSize.iconTile : NestSize.avatarMedium,
              iconSize: isLarge ? NestSize.iconLarge : NestSize.iconMedium,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Text(
                room?.name ?? HomeCareRoutineCopy.roomGone,
                style: isLarge ? nest.text.headline : nest.text.title,
              ),
            ),
            if (day.isDone) ...[
              const SizedBox(width: NestSpace.sm),
              const NestTag(
                label: HomeCareRoutineCopy.roomDone,
                icon: LucideIcons.circleCheck,
                tone: NestTagTone.success,
              ),
            ],
          ],
        ),
        const SizedBox(height: NestSpace.md),
        StepProgressBar(
          progress: day.progress,
          height: isLarge ? NestSpace.md : NestSpace.sm,
          label: HomeCareRoutineCopy.done(day.doneCount, day.itemCount),
        ),
      ],
    );
  }
}
