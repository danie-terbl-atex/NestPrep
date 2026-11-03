import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/basket_compare_copy.dart';
import '../../groceries/model/product_match.dart';
import '../model/basket_comparison.dart';
import 'basket_verdict_card.dart';
import 'item_comparison_card.dart';
import 'shop_total_card.dart';

/// *Compare shops*, given what it shows (basket-compare ADR-0001): the
/// verdict, each shop's basket, the items some shop lacks before the items
/// every shop has, and — for somebody who may edit the list — one shop for
/// the whole list. Everything scrolls as one list, so nothing fixed squeezes
/// it at 200% text (`FE-14`).
class BasketCompareBody extends StatelessWidget {
  const BasketCompareBody({
    required this.comparison,
    required this.onRetry,
    this.area,
    this.leftOut = 0,
    this.banner,
    this.useShop,
    super.key,
  });

  final AsyncState<BasketComparison> comparison;
  final VoidCallback onRetry;

  /// Where the prices are from; null for near the phone.
  final String? area;

  /// Unbought items past the comparison's limit, not compared.
  final int leftOut;
  final Widget? banner;

  /// Null for somebody who may only read the list.
  final UseShopActions? useShop;

  @override
  Widget build(BuildContext context) => NestAsyncView<BasketComparison>(
    state: comparison,
    isEmpty: (comparison) => comparison.items.isEmpty,
    onRetry: onRetry,
    emptyBuilder: (_) => const NestEmptyView(
      icon: LucideIcons.shoppingBasket,
      title: BasketCompareCopy.emptyTitle,
      message: BasketCompareCopy.emptyBody,
    ),
    dataBuilder: (_, comparison) => _ComparisonList(
      comparison: comparison,
      onRetry: onRetry,
      area: area,
      leftOut: leftOut,
      banner: banner,
      useShop: useShop,
    ),
  );
}

/// What *Use this shop* needs from the screen.
@immutable
final class UseShopActions {
  const UseShopActions({
    required this.isApplying,
    required this.hasMatchesAt,
    required this.onUse,
  });

  final bool isApplying;
  final bool Function(ProductRetailer shop) hasMatchesAt;
  final ValueChanged<ProductRetailer> onUse;
}

class _ComparisonList extends StatelessWidget {
  const _ComparisonList({
    required this.comparison,
    required this.onRetry,
    required this.area,
    required this.leftOut,
    required this.banner,
    required this.useShop,
  });

  final BasketComparison comparison;
  final VoidCallback onRetry;
  final String? area;
  final int leftOut;
  final Widget? banner;
  final UseShopActions? useShop;

  /// A split is worth a line only when it saves at least a rand.
  static const _splitFloorCents = 100;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final shops = comparison.shops;
    final shopCount = shops.length;
    final totals = comparison.totals;
    final common = comparison.everywhere;
    final lacking = comparison.notEverywhere;
    final pending = [
      for (final item in comparison.items)
        if (!item.isSettledFor(shops)) item,
    ];
    final cheapest = comparison.cheapest?.shop;
    final splitLess = common.isEmpty
        ? null
        : totals
                  .map((total) => total.likeForLike)
                  .reduce((a, b) => a.compareTo(b) <= 0 ? a : b) -
              comparison.splitTotal;
    final actions = useShop;

    Widget item(ItemComparison item) => Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.sm),
      child: ItemComparisonCard(
        key: ValueKey('item-${item.item.id}'),
        item: item,
        shops: shops,
        onRetry: onRetry,
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (banner case final banner?)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: banner,
          ),
        BasketVerdictCard(comparison: comparison),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: BasketCompareCopy.totalsTitle),
        const SizedBox(height: NestSpace.sm),
        for (final total in totals)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: ShopTotalCard(
              key: ValueKey('total-${total.shop.code}'),
              total: total,
              itemCount: comparison.settledCount,
              shopCount: shopCount,
              isCheapest: total.shop == cheapest,
              showsLikeForLike:
                  common.isNotEmpty && totals.any((t) => t.missing > 0),
            ),
          ),
        if (splitLess != null && splitLess.cents >= _splitFloorCents)
          Padding(
            padding: const EdgeInsets.only(top: NestSpace.xs),
            child: SplitHint(total: comparison.splitTotal, less: splitLess),
          ),
        if (lacking.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          NestSectionHeader(
            title: BasketCompareCopy.notEverywhereTitle(shopCount),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final entry in lacking) item(entry),
        ],
        if (common.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          NestSectionHeader(
            title: BasketCompareCopy.everywhereTitle(shopCount),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final entry in common) item(entry),
        ],
        if (pending.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: BasketCompareCopy.stillChecking),
          const SizedBox(height: NestSpace.sm),
          for (final entry in pending) item(entry),
        ],
        if (leftOut > 0) ...[
          const SizedBox(height: NestSpace.sm),
          Text(
            BasketCompareCopy.leftOut(leftOut),
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
        if (actions != null) ...[
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: BasketCompareCopy.useTitle),
          Text(
            BasketCompareCopy.useBody,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.md),
          _UseShopButtons(
            shops: [?cheapest, ...shops.where((shop) => shop != cheapest)],
            cheapest: cheapest,
            canUse: comparison.isComplete,
            actions: actions,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        Text(
          BasketCompareCopy.footer(area),
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
        ),
      ],
    );
  }
}

class _UseShopButtons extends StatefulWidget {
  const _UseShopButtons({
    required this.shops,
    required this.cheapest,
    required this.canUse,
    required this.actions,
  });

  final List<ProductRetailer> shops;
  final ProductRetailer? cheapest;
  final bool canUse;
  final UseShopActions actions;

  @override
  State<_UseShopButtons> createState() => _UseShopButtonsState();
}

class _UseShopButtonsState extends State<_UseShopButtons> {
  ProductRetailer? _chosen;

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final shop in widget.shops)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestButton(
              key: ValueKey('use-${shop.code}'),
              label: BasketCompareCopy.useShop(shop),
              variant: shop == widget.cheapest
                  ? NestButtonVariant.primary
                  : NestButtonVariant.tonal,
              size: NestButtonSize.medium,
              isLoading: actions.isApplying && _chosen == shop,
              onPressed:
                  widget.canUse &&
                      !actions.isApplying &&
                      actions.hasMatchesAt(shop)
                  ? () {
                      setState(() => _chosen = shop);
                      actions.onUse(shop);
                    }
                  : null,
            ),
          ),
      ],
    );
  }
}
