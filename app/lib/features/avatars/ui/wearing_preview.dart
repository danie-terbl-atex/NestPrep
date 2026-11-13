import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_studio.dart';
import 'member_avatar.dart';

class WearingPreview extends StatelessWidget {
  const WearingPreview({
    required this.studio,
    required this.accessory,
    super.key,
  });

  final AvatarStudio studio;
  final AvatarAccessory accessory;

  @override
  Widget build(BuildContext context) {
    final look = studio.preview.copyWith(
      wear: {...studio.preview.wear, accessory.slot: accessory.id},
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final size =
            side / (1 + NestAvatar.topOverhang + NestAvatar.badgeOverhang);
        return Padding(
          padding: EdgeInsets.only(top: size * NestAvatar.topOverhang),
          child: Align(
            alignment: Alignment.topCenter,
            child: MemberAvatar(member: studio.member, look: look, size: size),
          ),
        );
      },
    );
  }
}
