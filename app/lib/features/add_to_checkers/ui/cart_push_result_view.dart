import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/cart_push_copy.dart';
import '../../groceries/model/product_match.dart';
import '../model/cart_push_result.dart';

/// What went into the member's cart at [shop] and what did not, in words a
/// person can act on, then the cart's count and total and where to finish.
class CartPushResultView extends StatelessWidget {
  const CartPushResultView({
    required this.shop,
    required this.result,
    required this.itemNames,
    required this.onDone,
    required this.onManageLink,
    super.key,
  });

  final ProductRetailer shop;
  final CartPushResult result;

  /// The list's names by item id, for the lines the server skipped.
  final Map<String, String> itemNames;
  final VoidCallback onDone;
  final VoidCallback onManageLink;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.addedNothing) ...[
          Text(CartPushCopy.emptyTitle, style: nest.text.title),
          Text(CartPushCopy.emptyBody, style: nest.text.bodySecondary),
        ] else ...[
          NestSectionHeader(
            title: CartPushCopy.addedCount(result.added.length),
          ),
          for (final line in result.added)
            _Line(
              key: ValueKey('added-${line.itemId}'),
              title: line.name,
              detail: line.price.display,
            ),
        ],
        if (result.skipped.isNotEmpty) ...[
          const SizedBox(height: NestSpace.md),
          NestSectionHeader(
            title: CartPushCopy.skippedCount(result.skipped.length),
          ),
          for (final line in result.skipped)
            _Line(
              key: ValueKey('skipped-${line.itemId}'),
              title: itemNames[line.itemId] ?? CartPushCopy.skipUnknown,
              detail: _reason(line.reason, shop),
            ),
        ],
        const SizedBox(height: NestSpace.lg),
        Text(
          CartPushCopy.cartSummary(result.cartItemCount, result.cartTotal),
          style: nest.text.bodyStrong,
        ),
        const SizedBox(height: NestSpace.xs),
        Text(CartPushCopy.finishIn(shop), style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.xl),
        NestButton(label: CartPushCopy.done, onPressed: onDone),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: CartPushCopy.manageLink(shop),
          variant: NestButtonVariant.ghost,
          onPressed: onManageLink,
        ),
      ],
    );
  }

  static String _reason(CartSkipReason reason, ProductRetailer shop) =>
      switch (reason) {
        CartSkipReason.noMatch => CartPushCopy.skipNoMatch(shop),
        CartSkipReason.outOfStock => CartPushCopy.skipOutOfStock,
        CartSkipReason.notFound => CartPushCopy.skipNotFound(shop),
        CartSkipReason.weighedItem => CartPushCopy.skipWeighed(shop),
        CartSkipReason.cartFull => CartPushCopy.skipCartFull(shop),
        CartSkipReason.lowStock => CartPushCopy.skipLowStock(shop),
        CartSkipReason.maxQuantity => CartPushCopy.skipMaxQuantity(shop),
        CartSkipReason.shopRefused => CartPushCopy.skipShopRefused(shop),
        CartSkipReason.unrecognised => CartPushCopy.skipUnknown,
      };
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.detail, super.key});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: nest.text.body),
          Text(
            detail,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}
