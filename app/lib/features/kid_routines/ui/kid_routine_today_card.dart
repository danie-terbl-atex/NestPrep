import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../todos/model/chore_picture.dart';
import '../model/kid_routine_run.dart';
import 'kid_routine_slot_look.dart';

/// One of a child's routines today, on their home (kid-routines ADR-0001):
/// the pictures of its steps in a row, the done ones ticked, and the whole
/// card the way into the player.
///
/// Progress is said in words and by the ticks, never by colour alone
/// (`FE-13`).
class KidRoutineTodayCard extends StatelessWidget {
  const KidRoutineTodayCard({
    required this.run,
    required this.canTick,
    required this.onOpen,
    super.key,
  });

  final KidRoutineRun run;
  final bool canTick;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final routine = run.routine;
    final finishBy = routine.finishBy;
    final progress = run.isFinished
        ? KidRoutineCopy.kidAllDone
        : KidRoutineCopy.kidProgress(run.doneCount, run.steps.length);
    final action = !canTick
        ? KidRoutineCopy.kidLook
        : run.isFinished
        ? KidRoutineCopy.kidAllDone
        : run.doneCount == 0
        ? KidRoutineCopy.kidStart
        : KidRoutineCopy.kidKeepGoing;
    return Semantics(
      button: true,
      onTap: onOpen,
      label: [
        routine.name,
        progress,
        if (routine.points > 0) PointsCopy.starsCount(routine.points),
        if (!run.isFinished || !canTick) action,
      ].join(', '),
      excludeSemantics: true,
      child: NestCard(
        variant: run.isFinished
            ? NestCardVariant.tinted
            : NestCardVariant.raised,
        padding: const EdgeInsets.all(NestSpace.lg),
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                NestIconTile(
                  icon: run.isFinished ? LucideIcons.check : routine.slot.icon,
                  tint: run.isFinished
                      ? NestTileTint.basil
                      : NestTileTint.butter,
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(routine.name, style: nest.text.title),
                      Text(
                        [
                          progress,
                          if (finishBy != null && !run.isFinished)
                            KidRoutineCopy.by(NestDates.timeOfDay(finishBy)),
                        ].join(' · '),
                        style: nest.text.caption.copyWith(
                          color: c.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: NestSpace.md),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final step in run.steps)
                  KidRoutineStepDot(
                    picture: step.picture,
                    isDone: run.isDone(step),
                  ),
              ],
            ),
            if (routine.points > 0 || (canTick && !run.isFinished)) ...[
              const SizedBox(height: NestSpace.md),
              Wrap(
                spacing: NestSpace.sm,
                runSpacing: NestSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (routine.points > 0)
                    NestTag(
                      label: PointsCopy.starsCount(routine.points),
                      tone: NestTagTone.warning,
                      icon: LucideIcons.star,
                    ),
                  if (canTick && !run.isFinished)
                    NestTag(
                      label: action,
                      tone: NestTagTone.accent,
                      icon: LucideIcons.play,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A step as its picture, with a tick over the corner once it is done. A step
/// with no picture is a plain dot, so the row still counts right.
class KidRoutineStepDot extends StatelessWidget {
  const KidRoutineStepDot({
    required this.picture,
    required this.isDone,
    this.size = NestSize.stickerSmall,
    this.isCurrent = false,
    super.key,
  });

  final String? picture;
  final bool isDone;
  final double size;
  final bool isCurrent;

  static const doneOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final sticker = ChorePicture.byId(picture);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isCurrent ? c.accentSoft : c.surfaceTint,
              borderRadius: BorderRadius.circular(NestRadius.sm),
              border: Border.all(
                color: isCurrent ? c.accent : c.outline,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: isDone ? doneOpacity : 1,
              child: sticker == null
                  ? Icon(
                      LucideIcons.circle,
                      size: NestSize.iconSmall,
                      color: c.inkSecondary,
                    )
                  : Padding(
                      padding: const EdgeInsets.all(NestSpace.xxs),
                      child: NestSticker(
                        asset: sticker.asset,
                        size: size - NestSpace.xs,
                      ),
                    ),
            ),
          ),
          if (isDone)
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.successSoft,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(NestSpace.xxs),
                  child: Icon(
                    LucideIcons.check,
                    size: NestSize.iconBadge,
                    color: c.success,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
