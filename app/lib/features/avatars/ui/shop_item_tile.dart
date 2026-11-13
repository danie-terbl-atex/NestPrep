import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_studio.dart';
import 'wearing_preview.dart';

class ShopItemTile extends StatelessWidget {
  const ShopItemTile({
    required this.studio,
    required this.accessory,
    required this.isBuying,
    required this.onBuy,
    super.key,
  });

  final AvatarStudio studio;
  final AvatarAccessory accessory;
  final bool isBuying;
  final ValueChanged<AvatarAccessory> onBuy;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: AvatarCopy.buyConfirm(accessory.label, accessory.stars),
      message: AvatarCopy.buyConfirmBody,
      confirmLabel: AvatarCopy.buyYes,
      cancelLabel: AvatarCopy.buyNotYet,
    );
    if (confirmed == true) onBuy(accessory);
  }

  @override
  Widget build(BuildContext context) {
    final more = accessory.stars - studio.stars;
    final canAfford = more <= 0;
    return NestPickTile(
      label: accessory.label,
      semanticLabel: canAfford
          ? '${accessory.label}. ${AvatarCopy.buyFor(accessory.stars)}'
          : '${accessory.label}. ${AvatarCopy.moreStars(more)}',
      onTap: canAfford && !isBuying ? () => _confirm(context) : null,
      picture: WearingPreview(studio: studio, accessory: accessory),
      footer: isBuying
          ? const SizedBox.square(
              dimension: NestSize.iconMedium,
              child: CircularProgressIndicator.adaptive(),
            )
          : NestTag(
              label: '${accessory.stars}',
              tone: canAfford ? NestTagTone.warning : NestTagTone.neutral,
              icon: canAfford ? LucideIcons.star : LucideIcons.lock,
              isFigure: true,
            ),
    );
  }
}
