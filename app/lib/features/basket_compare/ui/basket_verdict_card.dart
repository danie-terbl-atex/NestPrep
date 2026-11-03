import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/basket_compare_copy.dart';
import '../../add_to_checkers/ui/retailer_logo.dart';
import '../model/basket_comparison.dart';

/// The answer first (basket-compare ADR-0001 §4): which shop is cheapest on
/// the items every shop has, and by how much — with the shops' progress
/// above it while they are still answering.
class BasketVerdictCard extends StatelessWidget {
  const BasketVerdictCard({required this.comparison, super.key});

  final BasketComparison comparison;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final shopCount = comparison.shops.length;
    final common = comparison.everywhere;
    final best = comparison.cheapest;
    final (key, title, body, logo) = switch (best) {
      final ShopTotal winner => (
        'cheapest-${winner.shop.code}',
        BasketCompareCopy.cheapest(winner.shop),
        BasketCompareCopy.saving(comparison.saving, common.length, shopCount),
        RetailerLogo.decorative(
          retailer: winner.shop,
          size: NestSize.logoMedium,
        ),
      ),
      null when common.isNotEmpty => (
        'tie',
        BasketCompareCopy.samePrice(shopCount),
        BasketCompareCopy.samePriceBody(
          comparison.totals.first.likeForLike,
          common.length,
          shopCount,
        ),
        null,
      ),
      null when comparison.isComplete => (
        'no-common',
        BasketCompareCopy.noCommonTitle,
        BasketCompareCopy.noCommonBody(shopCount),
        null,
      ),
      null => (
        'waiting',
        BasketCompareCopy.waitingTitle,
        BasketCompareCopy.waitingBody,
        null,
      ),
    };
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!comparison.isComplete) ...[
            _Progress(
              settled: comparison.settledCount,
              total: comparison.items.length,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          AnimatedSwitcher(
            duration: NestMotion.of(context).standard,
            switchInCurve: NestMotion.enter,
            switchOutCurve: NestMotion.exit,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, ?current],
            ),
            child: Column(
              key: ValueKey(key),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (logo != null) ...[
                      logo,
                      const SizedBox(width: NestSpace.md),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: nest.text.title),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NestSpace.sm),
                Text(body, style: nest.text.bodySecondary),
                if (best != null && !comparison.isComplete) ...[
                  const SizedBox(height: NestSpace.xs),
                  Text(
                    BasketCompareCopy.soFar,
                    style: nest.text.caption.copyWith(
                      color: nest.colors.inkTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.settled, required this.total});

  final int settled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      label: BasketCompareCopy.checkingSemantics(settled, total),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            BasketCompareCopy.checking(settled, total),
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(NestRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: total == 0 ? 0 : settled / total),
              duration: NestMotion.of(context).slow,
              curve: NestMotion.enter,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: NestSpace.xs,
                backgroundColor: nest.colors.surfaceTint,
                color: nest.colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
