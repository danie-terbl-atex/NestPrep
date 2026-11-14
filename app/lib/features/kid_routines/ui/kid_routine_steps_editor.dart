import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../todos/model/chore_picture.dart';
import '../../todos/ui/chore_picture_view.dart';
import '../model/kid_routine_starter.dart';
import '../model/kid_routine_step.dart';

/// A kid routine's steps as a parent orders them (kid-routines ADR-0001):
/// each opens to change, a handle drags it, and ready-made steps are one tap
/// each with their sticker.
class KidRoutineStepsEditor extends StatelessWidget {
  const KidRoutineStepsEditor({
    required this.steps,
    required this.canAdd,
    required this.quickAdds,
    required this.onOpen,
    required this.onAdd,
    required this.onQuickAdd,
    required this.onMove,
    this.errorText,
    super.key,
  });

  final List<KidRoutineStep> steps;
  final bool canAdd;
  final List<KidRoutineStarter> quickAdds;
  final ValueChanged<KidRoutineStep> onOpen;
  final VoidCallback onAdd;
  final ValueChanged<KidRoutineStarter> onQuickAdd;

  /// As `ReorderableListView.onReorderItem` reports it.
  final void Function(int from, int to) onMove;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final error = errorText;
    final written = {for (final step in steps) step.title.toLowerCase()};
    final offered = [
      for (final starter in quickAdds)
        if (!written.contains(starter.title.toLowerCase())) starter,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: steps.length,
          onReorderItem: onMove,
          itemBuilder: (context, index) {
            final step = steps[index];
            return NestListRow(
              key: ValueKey('kid-routine-step-${step.id}'),
              title: step.title,
              subtitle: step.parts.isEmpty
                  ? step.note
                  : KidRoutineCopy.partsCount(step.parts.length),
              leading: _StepPicture(number: index + 1, picture: step.picture),
              onTap: () => onOpen(step),
              trailing: ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: '${KidRoutineCopy.moveStep} ${step.title}',
                  child: SizedBox.square(
                    dimension: NestSize.touchTarget,
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: NestSize.iconMedium,
                      color: c.inkSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (error != null) ...[
          const SizedBox(height: NestSpace.xs),
          Text(error, style: nest.text.caption.copyWith(color: c.danger)),
        ],
        if (canAdd) ...[
          const SizedBox(height: NestSpace.md),
          NestButton(
            key: const ValueKey('kid-routine-add-step'),
            label: KidRoutineCopy.addStep,
            icon: LucideIcons.plus,
            variant: NestButtonVariant.tonal,
            onPressed: onAdd,
          ),
          if (offered.isNotEmpty) ...[
            const SizedBox(height: NestSpace.lg),
            Text(
              KidRoutineCopy.suggestedSteps,
              style: nest.text.caption.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: NestSpace.sm),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final starter in offered)
                  _QuickAdd(starter: starter, onTap: () => onQuickAdd(starter)),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// The step's sticker, or its place in the order when it has none.
class _StepPicture extends StatelessWidget {
  const _StepPicture({required this.number, required this.picture});

  final int number;
  final String? picture;

  @override
  Widget build(BuildContext context) {
    if (ChorePicture.byId(picture) != null) {
      return ChorePictureView(id: picture);
    }
    final nest = NestTheme.of(context);
    return ExcludeSemantics(
      child: Container(
        width: NestSize.stickerSmall,
        height: NestSize.stickerSmall,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: nest.colors.accentSoft,
        ),
        child: Text('$number', style: nest.text.label),
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.starter, required this.onTap});

  final KidRoutineStarter starter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final picture = ChorePicture.byId(starter.picture);
    return Semantics(
      container: true,
      button: true,
      label: '${KidRoutineCopy.addStep}: ${starter.title}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.outline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('kid-routine-quick-${starter.picture}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              NestSpace.xs,
              NestSpace.xs,
              NestSpace.lg,
              NestSpace.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (picture != null) NestSticker(asset: picture.asset),
                const SizedBox(width: NestSpace.sm),
                Flexible(child: Text(starter.title, style: nest.text.label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
