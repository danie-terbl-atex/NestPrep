import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/ui/art/lunch_glyph.dart';
import '../model/lunch_idea.dart';

/// One idea on the list: the compartment's drawing, the idea, why, for whom
/// — and, for each child it was left out for, the reason. An idea left out
/// for everybody is struck through and is not searched.
class PlanWeekIdeaRow extends StatelessWidget {
  const PlanWeekIdeaRow({
    required this.idea,
    required this.childNames,
    required this.onRemove,
    this.shelfKept,
    super.key,
  });

  final LunchIdea idea;

  /// For a shelf of the lunchbox aisle, how many of its products were kept.
  final int? shelfKept;
  final Map<String, String> childNames;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final names = [
      for (final childId in idea.childIds) childNames[childId] ?? '',
    ].where((name) => name.isNotEmpty).join(', ');
    final title = idea.isStruckOut
        ? nest.text.body.copyWith(
            decoration: TextDecoration.lineThrough,
            color: nest.colors.inkTertiary,
          )
        : nest.text.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: idea.isStruckOut ? 0.5 : 1,
            child: LunchGlyph(slot: idea.slot, size: NestSize.iconMedium),
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(idea.idea, style: title),
                if (idea.why.isNotEmpty)
                  Text(idea.why, style: nest.text.bodySecondary),
                Text(switch (idea.isStruckOut) {
                  true when idea.origin == IdeaOrigin.aisle =>
                    PlanWeekCopy.shelfNothingKept,
                  true => PlanWeekCopy.leftOutForEveryone,
                  false => PlanWeekCopy.forChildren(names),
                }, style: nest.text.caption),
                if (shelfKept case final kept? when kept > 0)
                  Text(PlanWeekCopy.shelfKept(kept), style: nest.text.caption),
                for (final reason in idea.excluded)
                  Text(
                    PlanWeekCopy.reason(
                      reason,
                      childName: childNames[reason.childId],
                    ),
                    style: nest.text.caption.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  ),
                if (_originTag(idea.origin) case final tag?)
                  Padding(
                    padding: const EdgeInsets.only(top: NestSpace.xs),
                    child: tag,
                  ),
              ],
            ),
          ),
          NestIconButton(
            icon: LucideIcons.x,
            label: PlanWeekCopy.removeIdea(idea.idea),
            variant: NestIconButtonVariant.plain,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  static Widget? _originTag(IdeaOrigin origin) => switch (origin) {
    IdeaOrigin.own => const NestTag(label: PlanWeekCopy.originOwn),
    IdeaOrigin.aisle => const NestTag(
      label: PlanWeekCopy.originAisle,
      tone: NestTagTone.accent,
      icon: LucideIcons.store,
    ),
    IdeaOrigin.drafted || IdeaOrigin.usual => null,
  };
}
