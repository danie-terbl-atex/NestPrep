import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../todos/ui/chore_picture_view.dart';
import '../model/kid_routine_run.dart';
import '../model/kid_routine_step.dart';
import '../state/kid_routine_day_controller.dart';
import 'kid_routine_today_card.dart';

/// Opens the player over the child's home, on the same live read.
Future<void> showKidRoutinePlayer(
  BuildContext context, {
  required KidRoutineDayController controller,
  required String routineId,
  required String kidName,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: controller,
      child: KidRoutinePlayer(routineId: routineId, kidName: kidName),
    ),
  ),
);

/// A routine one step at a time (kid-routines ADR-0001): the step's picture
/// as big as the page allows, its word under it, one button, and the path of
/// every step along the bottom.
///
/// The page follows the child: it opens on the first step not yet done and
/// moves on after each tick. A child may tap any step on the path to look at
/// it, and untick one tapped by accident without asking anybody. The things
/// to remember under a step are ticked off on this screen only; they are a
/// memory aid, not a record.
class KidRoutinePlayer extends StatefulWidget {
  const KidRoutinePlayer({
    required this.routineId,
    required this.kidName,
    super.key,
  });

  final String routineId;
  final String kidName;

  static const doneKey = ValueKey('kid-routine-step-done');
  static const undoKey = ValueKey('kid-routine-step-undo');

  @override
  State<KidRoutinePlayer> createState() => _KidRoutinePlayerState();
}

class _KidRoutinePlayerState extends State<KidRoutinePlayer> {
  String? _lookingAt;
  final _packed = <String>{};
  int _cheers = 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KidRoutineDayController>();
    final run = controller.runFor(widget.routineId);
    final close = NestIconButton(
      icon: LucideIcons.x,
      label: KidRoutineCopy.kidClose,
      variant: NestIconButtonVariant.plain,
      onPressed: () => Navigator.of(context).pop(),
    );
    if (run == null) {
      return NestScaffold(
        leading: close,
        body: const NestEmptyView(
          title: KidRoutineCopy.kidGoneTitle,
          message: KidRoutineCopy.kidGoneBody,
          icon: LucideIcons.sun,
        ),
      );
    }
    final steps = run.steps;
    final picked = steps.indexWhere((step) => step.id == _lookingAt);
    final index = picked < 0 ? run.currentIndex : picked;
    final step = steps[index];
    final failure = controller.actionFailure;
    return NestScaffold(
      title: run.routine.name,
      eyebrow: KidRoutineCopy.kidStepOf(index + 1, steps.length),
      leading: close,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: _StepStage(
                key: ValueKey('kid-routine-step-${step.id}'),
                run: run,
                step: step,
                next: index + 1 < steps.length ? steps[index + 1] : null,
                cheers: _cheers,
                packed: _packed,
                onPack: (partId) => setState(() {
                  if (!_packed.remove(partId)) _packed.add(partId);
                }),
              ),
            ),
          ),
          const SizedBox(height: NestSpace.md),
          if (controller.canTick)
            run.isDone(step)
                ? NestButton(
                    key: KidRoutinePlayer.undoKey,
                    label: KidRoutineCopy.kidStepUndo,
                    icon: LucideIcons.undo2,
                    variant: NestButtonVariant.tonal,
                    onPressed: () => _toggle(controller, run, step),
                  )
                : NestButton(
                    key: KidRoutinePlayer.doneKey,
                    label: KidRoutineCopy.kidStepDone,
                    icon: LucideIcons.check,
                    onPressed: () => _toggle(controller, run, step),
                  ),
          const SizedBox(height: NestSpace.lg),
          _Path(
            run: run,
            index: index,
            onPick: (step) => setState(() => _lookingAt = step.id),
          ),
          const SizedBox(height: NestSpace.lg),
        ],
      ),
    );
  }

  Future<void> _toggle(
    KidRoutineDayController controller,
    KidRoutineRun run,
    KidRoutineStep step,
  ) async {
    final finishes = run.finishesWith(step);
    final ticking = !run.isDone(step);
    if (finishes) {
      final points = run.routine.points;
      NestCelebration.show(
        context,
        title: KidCopy.allDone(widget.kidName.trim().split(' ').first),
        message: run.routine.name,
        note: points > 0 ? PointsCopy.plusStars(points) : null,
      );
    }
    setState(() {
      _lookingAt = ticking ? null : step.id;
      if (ticking && !finishes) _cheers++;
    });
    await controller.toggle(run, step);
    if (finishes && mounted && controller.actionFailure == null) {
      Navigator.of(context).pop();
    }
  }
}

class _StepStage extends StatelessWidget {
  const _StepStage({
    required this.run,
    required this.step,
    required this.next,
    required this.cheers,
    required this.packed,
    required this.onPack,
    super.key,
  });

  final KidRoutineRun run;
  final KidRoutineStep step;
  final KidRoutineStep? next;
  final int cheers;
  final Set<String> packed;
  final void Function(String partId) onPack;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final isDone = run.isDone(step);
    final parts = run.partsOf(step);
    final note = step.note;
    return Column(
      children: [
        const SizedBox(height: NestSpace.lg),
        NestStarBurst(
          burst: cheers,
          child: NestRiseIn(
            child: ChorePictureView(
              id: step.picture,
              size: NestSize.stickerStage,
              isFaded: isDone,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        Text(
          step.title,
          style: nest.text.headline,
          textAlign: TextAlign.center,
        ),
        if (isDone) ...[
          const SizedBox(height: NestSpace.sm),
          const NestTag(
            label: KidRoutineCopy.kidStepIsDone,
            tone: NestTagTone.success,
            icon: LucideIcons.check,
          ),
        ],
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: NestSpace.sm),
          Text(
            note,
            style: nest.text.body.copyWith(color: c.inkSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        if (parts.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          Text(KidRoutineCopy.kidRemember, style: nest.text.bodyStrong),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final part in parts)
                _PartTile(
                  part: part,
                  isPacked: packed.contains(part.id),
                  onTap: () => onPack(part.id),
                ),
            ],
          ),
        ],
        if (next case final next? when !isDone) ...[
          const SizedBox(height: NestSpace.xl),
          Text(
            KidRoutineCopy.kidNext(next.title),
            style: nest.text.caption.copyWith(color: c.inkSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: NestSpace.lg),
      ],
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.part,
    required this.isPacked,
    required this.onTap,
  });

  final KidRoutinePart part;
  final bool isPacked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      button: true,
      checked: isPacked,
      label: part.text,
      onTap: onTap,
      excludeSemantics: true,
      child: NestCard(
        variant: isPacked ? NestCardVariant.tinted : NestCardVariant.flat,
        padding: const EdgeInsets.symmetric(
          horizontal: NestSpace.md,
          vertical: NestSpace.sm,
        ),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (part.picture != null) ...[
              ChorePictureView(id: part.picture, isFaded: isPacked),
              const SizedBox(width: NestSpace.sm),
            ],
            Flexible(child: Text(part.text, style: nest.text.bodyStrong)),
            const SizedBox(width: NestSpace.sm),
            Icon(
              isPacked ? LucideIcons.circleCheck : LucideIcons.circle,
              size: NestSize.iconMedium,
              color: isPacked ? nest.colors.success : nest.colors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Path extends StatelessWidget {
  const _Path({required this.run, required this.index, required this.onPick});

  final KidRoutineRun run;
  final int index;
  final void Function(KidRoutineStep step) onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        for (final (at, step) in run.steps.indexed)
          Semantics(
            button: true,
            selected: at == index,
            onTap: () => onPick(step),
            label: KidRoutineCopy.kidStepLabel(
              step.title,
              isDone: run.isDone(step),
            ),
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('kid-routine-path-${step.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(step),
              child: KidRoutineStepDot(
                picture: step.picture,
                isDone: run.isDone(step),
                isCurrent: at == index,
                size: NestSize.touchTarget,
              ),
            ),
          ),
      ],
    );
  }
}
