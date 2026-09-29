import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../chore_points/model/kid_chore_note.dart';
import '../../chore_points/ui/kid_chore_stars.dart';
import '../../todos/model/task_occurrence.dart';

/// One of a kid's jobs, as a big tile the whole of which is the button
/// (accounts ADR-0003). Tapping it ticks the job off, and tapping again un-ticks
/// it — a child who tapped by accident can put it back without asking anybody.
///
/// The tick grows into place when a job is done. It is a change of state being
/// explained, not decoration, and under reduce-motion it simply appears
/// (`FE-15`). Done is said in words and by the icon as well as by colour
/// (`FE-13`).
///
/// With [onToggle] null — a grant of `view` on to-dos, which looks and does not
/// tick (accounts ADR-0004) — the tile is not a button and says no "tap".
///
/// A starred job also says what it is worth and where its stars are — earned,
/// waiting for a grown-up, or sent back for another go (todos ADR-0003).
class KidChoreTile extends StatelessWidget {
  const KidChoreTile({
    required this.chore,
    required this.isOverdue,
    required this.onToggle,
    this.note = const NoStars(),
    super.key,
  });

  final TaskOccurrence chore;
  final bool isOverdue;
  final VoidCallback? onToggle;
  final KidChoreNote note;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final isDone = chore.isDone;
    final status = isDone
        ? KidCopy.choreDone
        : isOverdue
        ? KidCopy.choreOverdue
        : onToggle == null
        ? KidCopy.choreToDo
        : KidCopy.choreTapToFinish;
    final stars = PointsCopy.kidNote(note);
    return Semantics(
      button: onToggle != null,
      checked: isDone,
      label: [chore.task.title, status, ?stars].join(', '),
      excludeSemantics: true,
      child: Material(
        color: isDone ? c.successSoft : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NestRadius.xl),
          side: BorderSide(color: isDone ? c.success : c.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: NestSize.controlHuge),
            child: Padding(
              padding: const EdgeInsets.all(NestSpace.md),
              child: Row(
                children: [
                  _Tick(isDone: isDone),
                  const SizedBox(width: NestSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(chore.task.title, style: nest.text.title),
                        Text(
                          status,
                          style: nest.text.label.copyWith(
                            color: isDone
                                ? c.success
                                : isOverdue
                                ? c.warning
                                : c.inkSecondary,
                          ),
                        ),
                        if (stars != null) ...[
                          const SizedBox(height: NestSpace.xs),
                          KidChoreStars(note: note),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final motion = NestMotion.of(context);
    final c = nest.colors;
    return AnimatedContainer(
      duration: motion.standard,
      curve: NestMotion.enter,
      width: NestSize.controlLarge,
      height: NestSize.controlLarge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? c.success : c.surfaceTint,
        border: Border.all(
          color: isDone ? c.success : c.outlineStrong,
          width: NestStroke.focus,
        ),
      ),
      child: AnimatedScale(
        scale: isDone ? 1 : 0,
        duration: motion.slow,
        curve: NestMotion.celebrate,
        child: Icon(
          Icons.check_rounded,
          size: NestSize.iconLarge,
          color: c.surface,
        ),
      ),
    );
  }
}
