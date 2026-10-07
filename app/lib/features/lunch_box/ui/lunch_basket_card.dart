import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_basket.dart';

/// The week's basket as a shopping list (lunch-box ADR-0012 §4): each thing,
/// how many packs to buy and what they cost at the till, and how many lunches
/// that covers across every child; the total under them. Budget mode and
/// *Plan my week* both show it.
class LunchBasketCard extends StatelessWidget {
  const LunchBasketCard({
    required this.basket,
    this.title = LunchBudgetCopy.basketTitle,
    this.body = LunchBudgetCopy.basketBody,
    super.key,
  });

  final LunchBasket basket;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          Text(body, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.md),
          if (basket.isEmpty)
            Text(LunchBudgetCopy.basketEmpty, style: nest.text.bodySecondary)
          else ...[
            for (final line in basket.lines)
              _Line(key: ValueKey('basket-${line.key}'), line: line),
            const Divider(),
            Text(
              LunchBudgetCopy.basketTotal(basket.total.display),
              style: nest.text.title,
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line, super.key});

  final LunchBasketLine line;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(line.name, style: nest.text.body),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  LunchBudgetCopy.basketBuy(line.packs),
                  style: nest.text.label,
                ),
              ),
              const SizedBox(width: NestSpace.md),
              Text(line.cost.display, style: nest.text.label),
            ],
          ),
          Text(
            LunchBudgetCopy.basketCovers(line.boxes),
            style: nest.text.caption,
          ),
        ],
      ),
    );
  }
}
