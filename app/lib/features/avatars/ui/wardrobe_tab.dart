import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_studio.dart';
import 'star_shop_section.dart';
import 'wardrobe_item_tile.dart';

class WardrobeTab extends StatelessWidget {
  const WardrobeTab({
    required this.studio,
    required this.isSelf,
    required this.isBuying,
    required this.onWear,
    required this.onBuy,
    super.key,
  });

  static const slots = [
    AvatarSlot.top,
    AvatarSlot.face,
    AvatarSlot.badge,
    AvatarSlot.ring,
  ];

  final AvatarStudio studio;
  final bool isSelf;
  final bool Function(String accessoryId) isBuying;
  final void Function(AvatarSlot slot, String? accessoryId) onWear;
  final ValueChanged<AvatarAccessory> onBuy;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AvatarCopy.wardrobeBody, style: nest.text.bodySecondary),
        for (final slot in slots)
          if (studio.library
                  .on(slot, hasFace: true)
                  .where(studio.canWear)
                  .toList()
              case final items
              when items.isNotEmpty &&
                  (slot != AvatarSlot.face ||
                      studio.hasFace ||
                      studio.nestlingName() == null)) ...[
            const SizedBox(height: NestSpace.xl),
            NestSectionHeader(title: AvatarCopy.slotTitle(slot)),
            const SizedBox(height: NestSpace.sm),
            if (slot == AvatarSlot.face && !studio.hasFace)
              Text(AvatarCopy.faceNeedsNestling, style: nest.text.caption)
            else
              NestPickGrid(
                children: [
                  for (final accessory in items)
                    WardrobeItemTile(
                      key: ValueKey('wear-${accessory.id}'),
                      studio: studio,
                      accessory: accessory,
                      onWear: onWear,
                    ),
                ],
              ),
          ],
        if (studio.isKid) ...[
          const SizedBox(height: NestSpace.xxl),
          if (studio.shopIsOpen)
            StarShopSection(
              studio: studio,
              isSelf: isSelf,
              isBuying: isBuying,
              onBuy: onBuy,
            )
          else
            NestCard(
              variant: NestCardVariant.flat,
              child: Text(AvatarCopy.shopClosed, style: nest.text.body),
            ),
        ],
      ],
    );
  }
}
