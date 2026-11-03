import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/basket_compare_copy.dart';
import '../../../shared/money/money.dart';
import '../../add_to_checkers/ui/retailer_logo.dart';
import '../../groceries/model/product_match.dart';
import '../model/basket_comparison.dart';

/// One list item across the compared shops: a line per shop, the cheapest
/// marked in words, and a shop without it said plainly rather than left out.
class ItemComparisonCard extends StatelessWidget {
  const ItemComparisonCard({
    required this.item,
    required this.shops,
    required this.onRetry,
    super.key,
  });

  final ItemComparison item;
  final List<ProductRetailer> shops;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final cheapest = item.cheapestOf(shops);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(item.item.name, style: nest.text.bodyStrong),
              ),
              if (item.packs > 1) ...[
                const SizedBox(width: NestSpace.sm),
                Text(
                  BasketCompareCopy.packs(item.packs),
                  style: nest.text.label.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
              ],
            ],
          ),
          for (final shop in shops) ...[
            const SizedBox(height: NestSpace.sm),
            ShopLineView(
              shop: shop,
              line: item.lines[shop],
              isCheapest: shop == cheapest,
              onRetry: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// One shop's answer for one item; [line] null while the shop is still
/// being asked.
class ShopLineView extends StatelessWidget {
  const ShopLineView({
    required this.shop,
    required this.line,
    required this.isCheapest,
    required this.onRetry,
    super.key,
  });

  final ProductRetailer shop;
  final ShopLine? line;
  final bool isCheapest;
  final VoidCallback onRetry;

  static const _pendingWidth = 160.0;

  @override
  Widget build(BuildContext context) {
    final content = switch (line) {
      final ShopOffer offer => _Offer(offer: offer, isCheapest: isCheapest),
      ShopMiss(:final reason) => _Missing(shop: shop, reason: reason),
      ShopUnreachable() => _Unreachable(shop: shop, onRetry: onRetry),
      null => Semantics(
        label: BasketCompareCopy.checkingAt(shop),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: NestSkeleton(
            height: NestSpace.lg,
            width: _pendingWidth,
            radius: NestRadius.xs,
          ),
        ),
      ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Every line's words name the shop for a screen reader.
        RetailerLogo.decorative(retailer: shop),
        const SizedBox(width: NestSpace.sm),
        Expanded(child: content),
      ],
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.offer, required this.isCheapest});

  final ShopOffer offer;
  final bool isCheapest;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final muted = nest.text.caption.copyWith(color: nest.colors.inkTertiary);
    final oldPrice = offer.oldPrice;
    final note = switch (offer.source) {
      ShopOfferSource.pickedEarlier => BasketCompareCopy.pickedEarlier,
      ShopOfferSource.closest => BasketCompareCopy.closest,
      ShopOfferSource.picked || ShopOfferSource.matched => null,
    };
    return Semantics(
      label: BasketCompareCopy.offerSemantics(
        offer.shop,
        offer.name,
        offer.total,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    offer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nest.text.label,
                  ),
                ),
                const SizedBox(width: NestSpace.sm),
                Text(offer.total.display, style: nest.text.bodyStrong),
              ],
            ),
          ),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (offer.packs > 1)
                Text(
                  BasketCompareCopy.perPack(offer.unitPrice, offer.packs),
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
              if (oldPrice != null)
                Text(
                  BasketCompareCopy.was(
                    Money(
                      oldPrice.cents * offer.packs,
                      currency: oldPrice.currency,
                    ),
                  ),
                  style: muted.copyWith(decoration: TextDecoration.lineThrough),
                ),
              if (offer.isOnPromotion)
                const NestBadge(
                  label: BasketCompareCopy.deal,
                  tone: NestBadgeTone.info,
                  icon: LucideIcons.tag,
                ),
              if (isCheapest)
                const NestTag(
                  label: BasketCompareCopy.cheapestTag,
                  tone: NestTagTone.success,
                  icon: LucideIcons.badgeCheck,
                ),
              if (note != null) Text(note, style: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.shop, required this.reason});

  final ProductRetailer shop;
  final ShopMissReason reason;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final (icon, label) = switch (reason) {
      ShopMissReason.notFound => (
        LucideIcons.searchX,
        BasketCompareCopy.notAt(shop),
      ),
      ShopMissReason.outOfStock => (
        LucideIcons.packageX,
        BasketCompareCopy.outOfStockAt(shop),
      ),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: nest.colors.warningSoft,
          borderRadius: BorderRadius.circular(NestRadius.xs),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NestSpace.sm,
            vertical: NestSpace.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: NestSize.iconSmall, color: nest.colors.warning),
              const SizedBox(width: NestSpace.xs),
              Flexible(
                child: Text(
                  label,
                  style: nest.text.label.copyWith(color: nest.colors.warning),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.shop, required this.onRetry});

  final ProductRetailer shop;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Wrap(
      spacing: NestSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.cloudOff,
              size: NestSize.iconSmall,
              color: nest.colors.inkTertiary,
            ),
            const SizedBox(width: NestSpace.xs),
            Flexible(
              child: Text(
                BasketCompareCopy.unreachable(shop),
                style: nest.text.caption.copyWith(
                  color: nest.colors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
        NestButton(
          key: ValueKey('retry-${shop.code}'),
          label: BasketCompareCopy.retry,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          icon: LucideIcons.refreshCw,
          isExpanded: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
