import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/basket_compare_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/basket_compare_copy.dart';
import '../../add_to_checkers/ui/retailer_logo.dart';
import '../../groceries/model/product_match.dart';

/// The grocery list's way into *Compare shops* (basket-compare ADR-0001):
/// quiet, one row, the shops' own logos leading.
class CompareShopsEntry extends StatelessWidget {
  const CompareShopsEntry({
    required this.householdId,
    required this.shops,
    super.key,
  });

  final String householdId;
  final List<ProductRetailer> shops;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      button: true,
      child: NestCard(
        key: const ValueKey('compare-shops'),
        variant: NestCardVariant.flat,
        padding: const EdgeInsets.all(NestSpace.md),
        onTap: () => context.push(BasketCompareRoute.pathFor(householdId)),
        child: Row(
          children: [
            for (final shop in shops) ...[
              RetailerLogo.decorative(retailer: shop),
              const SizedBox(width: NestSpace.xs),
            ],
            const SizedBox(width: NestSpace.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(BasketCompareCopy.entryTitle, style: nest.text.label),
                  Text(
                    BasketCompareCopy.entryBody(shops),
                    style: nest.text.caption.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: NestSpace.sm),
            Icon(
              LucideIcons.chevronRight,
              size: NestSize.iconSmall,
              color: nest.colors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
