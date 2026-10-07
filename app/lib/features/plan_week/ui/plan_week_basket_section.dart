import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_budget_reading.dart';
import '../../lunch_box/ui/lunch_basket_card.dart';
import '../model/shop_week.dart';

/// The week's basket and the budget it is read against (lunch-box ADR-0012
/// §4): every new lunch's product as whole packs to buy, then one gentle
/// sentence — room left, nearly there, or how far over — never red
/// (ADR-0007 §5).
class PlanWeekBasketSection extends StatelessWidget {
  const PlanWeekBasketSection({required this.plan, super.key});

  final ShopWeek plan;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final basket = plan.basket;
    final budget = plan.budget;
    final reading = budget == null
        ? null
        : LunchBudgetReading(spent: basket.total, budget: budget);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LunchBasketCard(
          basket: basket,
          title: PlanWeekCopy.basketHeadline,
          body: PlanWeekCopy.basketBody,
        ),
        const SizedBox(height: NestSpace.md),
        if (reading == null)
          Text(PlanWeekCopy.noBudget, style: nest.text.bodySecondary)
        else
          NestToneRow(
            icon: LucideIcons.piggyBank,
            tone: reading.band == LunchBudgetBand.over
                ? NestTagTone.warning
                : NestTagTone.success,
            title: LunchBudgetCopy.spentOf(
              reading.spent.display,
              reading.budget.displayShort,
            ),
            subtitle: switch (reading.band) {
              LunchBudgetBand.calm => LunchBudgetCopy.left(
                reading.difference.display,
              ),
              LunchBudgetBand.nearly => LunchBudgetCopy.nearly(
                reading.difference.display,
              ),
              LunchBudgetBand.over => LunchBudgetCopy.over(
                reading.difference.display,
              ),
            },
          ),
      ],
    );
  }
}
