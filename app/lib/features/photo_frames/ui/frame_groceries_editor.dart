import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import '../../add_to_checkers/model/checkers_area.dart';
import '../../groceries/model/product_match.dart';
import '../model/frame_groceries.dart';

/// *Add groceries from the frame*, and the shop and area it picks products
/// at. Offered while a shop is switched on; a frame already adding keeps its
/// shop, offered or not, until somebody switches it off. Switched on, it
/// starts at [defaultShop] when that is offered.
class FrameGroceriesEditor extends StatelessWidget {
  const FrameGroceriesEditor({
    required this.groceries,
    required this.shopsOn,
    required this.defaultShop,
    required this.defaultArea,
    required this.onChanged,
    super.key,
  });

  final FrameGroceries? groceries;
  final List<ProductRetailer> shopsOn;
  final ProductRetailer? defaultShop;
  final CheckersArea defaultArea;
  final ValueChanged<FrameGroceries?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final current = groceries;
    final shops = [
      for (final shop in ProductRetailer.values)
        if (shopsOn.contains(shop) || shop == current?.shop) shop,
    ];
    if (shops.isEmpty) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    final change = onChanged;
    final startShop = switch (defaultShop) {
      final shop? when shops.contains(shop) => shop,
      _ => shops.first,
    };
    void toggle(bool on) => change?.call(
      on ? FrameGroceries(shop: startShop, area: defaultArea) : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestListRow(
          title: PhotoFrameCopy.groceries,
          subtitle: PhotoFrameCopy.groceriesBody,
          leading: const NestIconTile(
            icon: LucideIcons.shoppingBasket,
            tint: NestTileTint.guava,
            size: NestSize.avatarMedium,
          ),
          trailing: Semantics(
            label: PhotoFrameCopy.groceries,
            child: Switch(
              value: current != null,
              onChanged: change == null ? null : toggle,
            ),
          ),
          onTap: change == null ? null : () => toggle(current == null),
        ),
        if (current != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpace.lg,
              NestSpace.xs,
              NestSpace.lg,
              NestSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(PhotoFrameCopy.groceriesShop, style: nest.text.caption),
                const SizedBox(height: NestSpace.sm),
                Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.sm,
                  children: [
                    for (final shop in shops)
                      NestChip(
                        key: ValueKey(shop),
                        label: CheckersCopy.retailerName(shop),
                        isSelected: shop == current.shop,
                        onTap: change == null
                            ? null
                            : () => change(current.copyWith(shop: shop)),
                      ),
                  ],
                ),
                const SizedBox(height: NestSpace.md),
                Text(PhotoFrameCopy.groceriesArea, style: nest.text.caption),
                const SizedBox(height: NestSpace.sm),
                Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.sm,
                  children: [
                    for (final area in CheckersArea.values)
                      NestChip(
                        key: ValueKey(area),
                        label: area.label,
                        isSelected: area == current.area,
                        onTap: change == null
                            ? null
                            : () => change(current.copyWith(area: area)),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
