import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import 'step_number.dart';

/// One step of the helper's checklist, big enough to hit with wet hands or
/// gloves on: the whole tile is the checkbox, and it says whether it is
/// done in words as well as with the tick (`FE-13`).
class BigStepTile extends StatelessWidget {
  const BigStepTile({
    required this.number,
    required this.text,
    required this.isDone,
    required this.onToggle,
    this.english,
    super.key,
  });

  final int number;
  final String text;
  final bool isDone;

  /// The English beneath a translated step, when she asked to see both
  /// (home-care ADR-0006).
  final String? english;

  /// Null while the job cannot be worked — handed in, or not hers.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final motion = NestMotion.of(context);
    return Semantics(
      button: true,
      toggled: isDone,
      label: HomeCareCopy.stepForReader(number, text, isDone: isDone),
      excludeSemantics: true,
      child: Material(
        color: isDone ? nest.colors.successSoft : nest.colors.surface,
        borderRadius: BorderRadius.circular(NestRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: motion.quick,
            constraints: const BoxConstraints(minHeight: NestSize.controlHuge),
            padding: const EdgeInsets.all(NestSpace.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NestRadius.xl),
              border: Border.all(
                color: isDone ? nest.colors.success : nest.colors.outline,
                width: NestStroke.focus,
              ),
            ),
            child: Row(
              children: [
                StepNumber(
                  number: number,
                  isDone: isDone,
                  size: NestSize.avatarMedium,
                ),
                const SizedBox(width: NestSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: nest.text.title.copyWith(
                          color: isDone
                              ? nest.colors.inkSecondary
                              : nest.colors.ink,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (english case final String original) ...[
                        const SizedBox(height: NestSpace.xxs),
                        Text(original, style: nest.text.caption),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: NestSpace.sm),
                Icon(
                  isDone ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: NestSize.iconLarge,
                  color: isDone ? nest.colors.success : nest.colors.inkTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
