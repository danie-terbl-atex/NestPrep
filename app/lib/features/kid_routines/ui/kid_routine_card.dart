import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../todos/model/chore_picture.dart';
import '../model/kid_routine.dart';
import '../model/kid_routine_draft.dart';

/// One routine on the parent's screen (kid-routines ADR-0001): its name, when
/// it runs, and its steps as the child will see them — a row of stickers.
class KidRoutineCard extends StatelessWidget {
  const KidRoutineCard({
    required this.routine,
    required this.sharedWith,
    this.onTap,
    super.key,
  });

  final KidRoutine routine;

  /// The other children on it, by name.
  final List<String> sharedWith;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final finishBy = routine.finishBy;
    final summary = [
      KidRoutineCopy.daysSummary(KidRoutineDraft.of(routine).weekdays),
      KidRoutineCopy.stepCount(routine.steps.length),
      if (finishBy != null) KidRoutineCopy.by(NestDates.timeOfDay(finishBy)),
    ].join(' · ');
    final stickers = [
      for (final step in routine.steps) ?ChorePicture.byId(step.picture),
    ];
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(routine.name, style: nest.text.bodyStrong),
          const SizedBox(height: NestSpace.xs),
          Text(
            summary,
            style: nest.text.caption.copyWith(color: c.inkSecondary),
          ),
          if (sharedWith.isNotEmpty)
            Text(
              KidRoutineCopy.sharedWith(sharedWith),
              style: nest.text.caption.copyWith(color: c.inkSecondary),
            ),
          if (routine.points > 0) ...[
            const SizedBox(height: NestSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(
                label: PointsCopy.starsCount(routine.points),
                tone: NestTagTone.warning,
                icon: LucideIcons.star,
              ),
            ),
          ],
          if (stickers.isNotEmpty) ...[
            const SizedBox(height: NestSpace.md),
            ExcludeSemantics(
              child: Wrap(
                spacing: NestSpace.xs,
                runSpacing: NestSpace.xs,
                children: [
                  for (final sticker in stickers)
                    NestSticker(asset: sticker.asset),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
