import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_studio.dart';
import 'wearing_preview.dart';

class WardrobeItemTile extends StatelessWidget {
  const WardrobeItemTile({
    required this.studio,
    required this.accessory,
    required this.onWear,
    super.key,
  });

  final AvatarStudio studio;
  final AvatarAccessory accessory;
  final void Function(AvatarSlot slot, String? accessoryId) onWear;

  @override
  Widget build(BuildContext context) {
    final slot = accessory.slot;
    final isWorn = studio.wornOn(slot) == accessory.id;
    return NestPickTile(
      label: accessory.label,
      semanticLabel: isWorn
          ? AvatarCopy.takeOff(accessory.label)
          : AvatarCopy.wear(accessory.label),
      isSelected: isWorn,
      onTap: () => onWear(slot, isWorn ? null : accessory.id),
      picture: WearingPreview(studio: studio, accessory: accessory),
    );
  }
}
