import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_library.dart';
import '../model/avatar_studio.dart';
import 'shop_item_tile.dart';

class StarShopSection extends StatelessWidget {
  const StarShopSection({
    required this.studio,
    required this.isSelf,
    required this.isBuying,
    required this.onBuy,
    super.key,
  });

  final AvatarStudio studio;
  final bool isSelf;
  final bool Function(String accessoryId) isBuying;
  final ValueChanged<AvatarAccessory> onBuy;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final priced = [
      for (final accessory in studio.library.accessories)
        if (!accessory.isFree &&
            !studio.record.owns(accessory.id) &&
            (studio.hasFace || accessory.slot != AvatarSlot.face))
          accessory,
    ]..sort((a, b) => a.stars.compareTo(b.stars));
    if (priced.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: AvatarCopy.shopTitle),
        const SizedBox(height: NestSpace.xs),
        Text(
          isSelf
              ? AvatarCopy.shopBody(studio.stars)
              : AvatarCopy.shopBodyOf(studio.member.displayName, studio.stars),
          style: nest.text.bodySecondary,
        ),
        const SizedBox(height: NestSpace.md),
        NestPickGrid(
          children: [
            for (final accessory in priced)
              ShopItemTile(
                key: ValueKey('shop-${accessory.id}'),
                studio: studio,
                accessory: accessory,
                isBuying: isBuying(accessory.id),
                onBuy: onBuy,
              ),
          ],
        ),
      ],
    );
  }
}
