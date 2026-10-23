import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_budget_reading.dart';
import '../../lunch_box/ui/lunch_basket_card.dart';
import '../../lunch_box/ui/lunch_week_name.dart';
import '../model/shop_week.dart';

/// The week's basket and the budget it is read against (lunch-box ADR-0012
/// §4): every new lunch's product as whole packs to buy, then the whole
/// week — what is packed already and what this adds — against the budget in
/// one gentle sentence, room left, nearly there, or how far over, never red
/// (ADR-0007 §5). The total is the one the budget screen will show.
class PlanWeekBasketSection extends StatelessWidget {
  const PlanWeekBasketSection({
    required this.plan,
    required this.weekName,
    super.key,
  });

  final ShopWeek plan;
  final LunchWeekName weekName;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final basket = plan.basket;
    final reading = plan.reading;
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
        else ...[
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
          if (plan.alreadyPlanned case final already?) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              PlanWeekCopy.alreadyPlanned(already.display, weekName.inSentence),
              style: nest.text.bodySecondary,
            ),
          ],
        ],
      ],
    );
  }
}
