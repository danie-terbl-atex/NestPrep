import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/lunch_shop_copy.dart';
import '../../add_to_checkers/ui/retailer_logo.dart';
import '../../groceries/model/product_match.dart';

/// The brief's choice of shop (lunch-box ADR-0026): what it means in words,
/// then each shop *Plan my week* can plan at by its own logo, the chosen one
/// ringed and ticked. Renders what it is given and reports a tap (`FE-03`).
class PlanWeekShopPicker extends StatelessWidget {
  const PlanWeekShopPicker({
    required this.shops,
    required this.chosen,
    required this.onChoose,
    super.key,
  });

  final List<ProductRetailer> shops;
  final ProductRetailer chosen;
  final ValueChanged<ProductRetailer> onChoose;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LunchShopCopy.chooseShop, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final shop in shops)
              RetailerLogo(
                key: ValueKey('plan-week-shop-${shop.code}'),
                retailer: shop,
                size: NestSize.logoMedium,
                label: LunchShopCopy.shopChoice(shop),
                tone: shop == chosen
                    ? NestLogoTileTone.selected
                    : NestLogoTileTone.idle,
                onTap: () => onChoose(shop),
              ),
          ],
        ),
      ],
    );
  }
}
