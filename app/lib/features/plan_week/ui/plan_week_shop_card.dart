import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/lunch_shop_copy.dart';
import '../../add_to_checkers/ui/checkers_area_sheet.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_shop_picker.dart';

/// The shop in the brief: which shop — Checkers, or Pick n Pay while its
/// switch is on (lunch-box ADR-0026) — where the search will look, and a way
/// to choose the area, the same area the grocery list's matches use, kept on
/// this phone (add-to-checkers ADR-0003).
class PlanWeekShopCard extends StatelessWidget {
  const PlanWeekShopCard({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<PlanWeekController>();
    final retailer = controller.retailer;
    final shop = retailer.shop;
    final place = controller.places.place;
    final where = switch (place) {
      null => LunchShopCopy.shopFinding(shop),
      _ when place.isDevice => LunchShopCopy.shopNearYou(shop),
      _ => LunchShopCopy.shopNear(shop, place.area!.label),
    };
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(LunchShopCopy.shopHeader, style: nest.text.caption),
          const SizedBox(height: NestSpace.xs),
          if (retailer.canChoose) ...[
            PlanWeekShopPicker(
              shops: retailer.choices,
              chosen: shop,
              onChoose: retailer.choose,
            ),
            const SizedBox(height: NestSpace.sm),
          ],
          Text(where, style: nest.text.title),
          if (!retailer.canChoose)
            Text(LunchShopCopy.shopOnly, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NestButton(
              label: LunchShopCopy.changeArea,
              icon: LucideIcons.mapPin,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: () => showCheckersAreaSheet(
                context: context,
                current: place?.area,
                onChoose: controller.places.choose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
