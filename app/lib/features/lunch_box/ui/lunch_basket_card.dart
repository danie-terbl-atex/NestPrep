import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_basket.dart';

/// The week's basket, line by line (lunch-box ADR-0012 §4): each thing, its
/// boxes and whole packs across every child, and what it costs at the till;
/// the total under them. Budget mode and *Plan my week* both show it.
class LunchBasketCard extends StatelessWidget {
  const LunchBasketCard({
    required this.basket,
    this.title = LunchBudgetCopy.basketTitle,
    this.body = LunchBudgetCopy.basketBody,
    this.trailingOf,
    super.key,
  });

  final LunchBasket basket;
  final String title;
  final String body;

  /// Something to put at the end of a line — a way to correct its pack size.
  final Widget? Function(LunchBasketLine line)? trailingOf;

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
              _Line(
                key: ValueKey('basket-${line.key}'),
                line: line,
                trailing: trailingOf?.call(line),
              ),
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
  const _Line({required this.line, this.trailing, super.key});

  final LunchBasketLine line;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.name, style: nest.text.body),
                    Text(
                      LunchBudgetCopy.basketLine(line.boxes, line.packs),
                      style: nest.text.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NestSpace.md),
              Text(line.cost.display, style: nest.text.label),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }
}
