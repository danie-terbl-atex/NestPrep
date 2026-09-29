import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/grocery_plan_copy.dart';

/// The household's *keep the list in step* switch (groceries ADR-0002), with
/// what it will and will never do, and who last turned it on. Disabled, with
/// the reason, for somebody who cannot see every plan it would follow — who
/// may still turn it off.
class GroceryKeepInStepCard extends StatelessWidget {
  const GroceryKeepInStepCard({
    required this.isOn,
    required this.canChange,
    required this.onChanged,
    this.changedBy,
    super.key,
  });

  final bool isOn;
  final bool canChange;
  final ValueChanged<bool> onChanged;

  /// Who turned it on, when it is on and they are known.
  final String? changedBy;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final by = changedBy;
    return NestCard(
      variant: NestCardVariant.flat,
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(GroceryPlanCopy.keepInStep, style: nest.text.bodyStrong),
                  const SizedBox(height: NestSpace.xxs),
                  Text(
                    canChange
                        ? GroceryPlanCopy.keepInStepBody
                        : GroceryPlanCopy.keepInStepNeedsSight,
                    style: nest.text.caption,
                  ),
                  if (isOn && by != null) ...[
                    const SizedBox(height: NestSpace.xxs),
                    Text(
                      GroceryPlanCopy.turnedOnBy(by),
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: NestSpace.md),
            // Turning it off is always safe; only turning it on needs sight of
            // every plan.
            Switch(
              value: isOn,
              onChanged: canChange || isOn ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
