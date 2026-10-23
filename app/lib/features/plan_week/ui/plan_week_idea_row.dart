import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../groceries/model/product_match.dart';
import '../../lunch_box/ui/art/lunch_glyph.dart';
import '../model/lunch_idea.dart';
import 'plan_week_dish_line.dart';

/// One idea on the list: the compartment's drawing, the idea, why, for whom
/// — and, for each child it was left out for, the reason. An idea left out
/// for everybody is struck through and is not searched. A drafted main is a
/// dish, named as one, with its recipe a tap away (lunch-box ADR-0021).
class PlanWeekIdeaRow extends StatelessWidget {
  const PlanWeekIdeaRow({
    required this.idea,
    required this.childNames,
    required this.onRemove,
    required this.shop,
    this.shelfKept,
    super.key,
  });

  final LunchIdea idea;

  /// The shop the week is planned at, named on an aisle shelf's tag.
  final ProductRetailer shop;

  /// For a shelf of the lunchbox aisle, how many of its products were kept.
  final int? shelfKept;
  final Map<String, String> childNames;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final dish = idea.dish;
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
                Text(dish?.name ?? idea.idea, style: title),
                if (dish != null && dish.summary.isNotEmpty)
                  Text(dish.summary, style: nest.text.bodySecondary),
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
                if (dish != null && !idea.isStruckOut)
                  PlanWeekDishLine(dish: dish, shop: shop),
                if (_originTag(idea.origin, shop) case final tag?)
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

  static Widget? _originTag(IdeaOrigin origin, ProductRetailer shop) =>
      switch (origin) {
        IdeaOrigin.own => const NestTag(label: PlanWeekCopy.originOwn),
        IdeaOrigin.aisle => NestTag(
          label: PlanWeekCopy.originAisle(shop),
          tone: NestTagTone.accent,
          icon: LucideIcons.store,
        ),
        IdeaOrigin.drafted || IdeaOrigin.usual => null,
      };
}
