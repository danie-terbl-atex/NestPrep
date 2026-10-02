import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_budget_reading.dart';
import '../../lunch_box/ui/lunch_basket_card.dart';
import '../../lunch_box/ui/lunch_portion_stepper.dart';
import '../model/shop_week.dart';
import '../state/plan_week_controller.dart';

/// The week's basket and the budget it is read against (lunch-box ADR-0012
/// §4): every new lunch's product in whole packs, each with how many boxes a
/// pack does and a way to correct it, then one gentle sentence — room left,
/// nearly there, or how far over — never red (ADR-0007 §5).
class PlanWeekBasketSection extends StatelessWidget {
  const PlanWeekBasketSection({required this.plan, super.key});

  final ShopWeek plan;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final shop = context.read<PlanWeekController>().shop;
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
          // A wrap, so at large text the stepper moves under the words
          // rather than off the edge (`FE-14`).
          trailingOf: (line) => Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                PlanWeekCopy.perPack(line.boxesPerPack),
                style: nest.text.caption,
              ),
              LunchPortionStepper(
                name: line.name,
                portions: line.boxesPerPack,
                onChanged: (boxes) => shop.setBoxesPerPack(line.key, boxes),
              ),
            ],
          ),
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
