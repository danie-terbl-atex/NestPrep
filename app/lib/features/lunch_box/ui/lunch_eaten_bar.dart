import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_feedback.dart';

/// After school: did the box come home eaten? Two big thumbs, and a way to
/// say it item by item (lunch-box ADR-0003). Once answered it says what was
/// said, with a way to change it — the answer is what the next suggestions
/// learn from, so it should be easy to correct.
class LunchEatenBar extends StatelessWidget {
  const LunchEatenBar({
    required this.feedback,
    required this.onMark,
    required this.onMarkItems,
    super.key,
  });

  final LunchFeedback? feedback;

  /// Null for somebody who may only look.
  final ValueChanged<LunchVerdict>? onMark;
  final VoidCallback? onMarkItems;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final answer = feedback?.boxVerdict;
    if (answer != null) {
      final ate = answer == LunchVerdict.ate;
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: NestSpace.sm,
        runSpacing: NestSpace.xs,
        children: [
          NestTag(
            label: ate ? LunchCopy.ateItAll : LunchCopy.cameBackFull,
            tone: ate ? NestTagTone.success : NestTagTone.warning,
            icon: ate
                ? Icons.thumb_up_alt_rounded
                : Icons.thumb_down_alt_rounded,
          ),
          if (onMarkItems != null)
            NestButton(
              label: LunchCopy.changeMark,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: onMarkItems,
            ),
        ],
      );
    }
    final mark = onMark;
    if (mark == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(LunchCopy.cameHomeQuestion, style: nest.text.label),
        const SizedBox(height: NestSpace.sm),
        Row(
          children: [
            Expanded(
              child: NestButton(
                label: LunchCopy.ateIt,
                icon: Icons.thumb_up_alt_outlined,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                onPressed: () => mark(LunchVerdict.ate),
              ),
            ),
            const SizedBox(width: NestSpace.sm),
            Expanded(
              child: NestButton(
                label: LunchCopy.leftIt,
                icon: Icons.thumb_down_alt_outlined,
                variant: NestButtonVariant.outline,
                size: NestButtonSize.small,
                onPressed: () => mark(LunchVerdict.left),
              ),
            ),
          ],
        ),
        if (onMarkItems != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NestButton(
              label: LunchCopy.markItems,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: onMarkItems,
            ),
          ),
      ],
    );
  }
}
