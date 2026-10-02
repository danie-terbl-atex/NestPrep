import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../model/grocery_plan_view.dart';

/// The way in to *From this week's plans*, at the top of the list: how many
/// things the week's meals and lunch boxes still need, or — when the list is
/// kept in step — that it is. It says it, and asks; it never adds by itself
/// (groceries ADR-0002).
///
/// Shown only when there is something to say; the header button opens the
/// sheet either way.
class GroceryPlanPrompt extends StatelessWidget {
  const GroceryPlanPrompt({
    required this.view,
    required this.onReview,
    super.key,
  });

  final GroceryPlanView view;
  final VoidCallback onReview;

  /// Whether [view] has anything for the prompt to say.
  static bool hasSomethingToSay(GroceryPlanView view) =>
      view.changeCount > 0 || view.isKeptInStep;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final inStep = view.isKeptInStep && view.changeCount == 0;
    return NestRiseIn(
      child: NestCard(
        variant: NestCardVariant.tinted,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NestIconTile(
              icon: inStep ? LucideIcons.listChecks : LucideIcons.listPlus,
              tint: inStep ? NestTileTint.basil : NestTileTint.butter,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inStep
                        ? GroceryPlanCopy.inStep
                        : GroceryPlanCopy.needs(view.changeCount),
                    style: nest.text.bodyStrong,
                  ),
                  const SizedBox(height: NestSpace.xxs),
                  Text(
                    inStep
                        ? GroceryPlanCopy.inStepBody
                        : GroceryPlanCopy.needsBody,
                    style: nest.text.caption,
                  ),
                  const SizedBox(height: NestSpace.sm),
                  NestButton(
                    label: GroceryPlanCopy.review,
                    variant: NestButtonVariant.tonal,
                    size: NestButtonSize.small,
                    isExpanded: false,
                    onPressed: onReview,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
