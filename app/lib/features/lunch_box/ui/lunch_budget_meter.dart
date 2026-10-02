import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_budget_reading.dart';
import '../model/lunch_budget_week.dart';

/// The week against its budget, gently (lunch-box ADR-0007): the spend, a
/// bar that fills, and one calm sentence — green while there is room, the
/// warning tone past it, never red. Without a budget it says what was spent
/// and offers to set one.
class LunchBudgetMeter extends StatelessWidget {
  const LunchBudgetMeter({required this.week, required this.onEdit, super.key});

  final LunchBudgetWeek week;

  /// Null for somebody who may only look.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final reading = week.reading;
    final spent = week.spent.display;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(LunchBudgetCopy.thisWeek, style: nest.text.caption),
          const SizedBox(height: NestSpace.xs),
          Text(switch (reading) {
            null when week.cost.isAtLeast => LunchBudgetCopy.spentAtLeast(
              spent,
            ),
            null => LunchBudgetCopy.spentOnly(spent),
            final reading => LunchBudgetCopy.spentOf(
              spent,
              reading.budget.displayShort,
            ),
          }, style: nest.text.title),
          if (reading != null) ...[
            const SizedBox(height: NestSpace.md),
            _Bar(reading: reading),
            const SizedBox(height: NestSpace.sm),
            Text(_sentence(reading), style: nest.text.bodySecondary),
          ] else ...[
            const SizedBox(height: NestSpace.sm),
            Text(LunchBudgetCopy.noBudget, style: nest.text.bodySecondary),
          ],
          if (onEdit case final onEdit?) ...[
            const SizedBox(height: NestSpace.md),
            NestButton(
              label: reading == null
                  ? LunchBudgetCopy.setBudget
                  : LunchBudgetCopy.changeBudget,
              icon: LucideIcons.piggyBank,
              variant: NestButtonVariant.tonal,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: onEdit,
            ),
          ],
        ],
      ),
    );
  }

  static String _sentence(LunchBudgetReading reading) {
    final amount = reading.difference.display;
    return switch (reading.band) {
      LunchBudgetBand.calm => LunchBudgetCopy.left(amount),
      LunchBudgetBand.nearly => LunchBudgetCopy.nearly(amount),
      LunchBudgetBand.over => LunchBudgetCopy.over(amount),
    };
  }
}

/// The bar itself: filled to the spend, in the success tone until the week
/// passes its budget and in the warning tone after. The sentence beside it
/// carries the meaning, so the colour is never the only signal (`FE-13`).
class _Bar extends StatelessWidget {
  const _Bar({required this.reading});

  final LunchBudgetReading reading;

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    final isOver = reading.band == LunchBudgetBand.over;
    return Semantics(
      label: LunchBudgetCopy.meterLabel(
        reading.spent.display,
        reading.budget.displayShort,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NestRadius.pill),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: reading.fraction),
          duration: NestMotion.of(context).slow,
          curve: NestMotion.enter,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: NestSpace.md,
            backgroundColor: colors.surfaceTint,
            color: isOver ? colors.warning : colors.success,
          ),
        ),
      ),
    );
  }
}
