import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/home_care_product.dart';
import '../model/stock_level.dart';
import 'product_kind_look.dart';

/// One product and how much of it is left, with the four levels as big
/// buttons anybody who sees home care can press (home-care ADR-0005). A
/// product running low says it is on the grocery list — in words, not only
/// colour (`FE-13`).
class StockRow extends StatelessWidget {
  const StockRow({
    required this.product,
    required this.markedBy,
    required this.onMark,
    super.key,
  });

  final HomeCareProduct product;

  /// Who last marked it, when anybody has.
  final String? markedBy;
  final ValueChanged<StockLevel> onMark;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final who = markedBy;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestIconTile(
                icon: product.kind.icon,
                tint: product.kind.tint,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: nest.text.bodyStrong),
                    if (who != null)
                      Text(
                        HomeCareStockCopy.markedBy(who),
                        style: nest.text.caption,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (product.stock.isRunningOut) ...[
            const SizedBox(height: NestSpace.sm),
            const Align(
              alignment: Alignment.centerLeft,
              child: NestTag(
                label: HomeCareStockCopy.onTheList,
                icon: Icons.shopping_cart_outlined,
                tone: NestTagTone.warning,
              ),
            ),
          ],
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final level in StockLevel.values)
                NestChip(
                  label: HomeCareStockCopy.level(level),
                  icon: _iconFor(level),
                  isSelected: product.stock == level,
                  semanticLabel: HomeCareStockCopy.levelForReader(
                    product.name,
                    level,
                  ),
                  onTap: product.stock == level ? null : () => onMark(level),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(StockLevel level) => switch (level) {
    StockLevel.full => Icons.battery_full,
    StockLevel.half => Icons.battery_4_bar,
    StockLevel.low => Icons.battery_1_bar,
    StockLevel.out => Icons.battery_0_bar,
  };
}
