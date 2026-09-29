import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_item.dart';
import '../model/lunch_price.dart';
import 'art/lunch_glyph.dart';

/// One library item and what the household pays for it — per box, or a
/// pack and the boxes it does — or a tag saying it has no price yet.
class LunchPriceRow extends StatelessWidget {
  const LunchPriceRow({
    required this.item,
    required this.price,
    required this.onTap,
    super.key,
  });

  final LunchItem item;
  final LunchPrice? price;

  /// Null for somebody who may only look.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final price = this.price;
    return NestListRow(
      title: item.name,
      subtitle: switch (price) {
        null => null,
        final price when price.isPack => [
          LunchBudgetCopy.perPack(price.money.display, price.portions),
          LunchBudgetCopy.perBox(price.perBox.money.display),
        ].join(' · '),
        final price => LunchBudgetCopy.perBox(price.money.display),
      },
      leading: switch (item.slot) {
        null => null,
        final slot => LunchSlotTile(slot: slot, isEmpty: price == null),
      },
      footer: price == null
          ? const Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(label: LunchBudgetCopy.noPrice),
            )
          : null,
      onTap: onTap,
    );
  }
}
