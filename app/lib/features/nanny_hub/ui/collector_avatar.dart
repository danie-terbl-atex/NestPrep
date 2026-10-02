import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import 'collector_look.dart';
import 'nanny_photo.dart';

/// A collector's face at a fixed size: a listed person's photo, a household
/// member's coloured initials, or a quiet person icon when there is neither —
/// so a row never jumps as a photo arrives (`FE-18`).
class CollectorAvatar extends StatelessWidget {
  const CollectorAvatar({
    required this.look,
    this.size = NestSize.avatarLarge,
    super.key,
  });

  final CollectorLook look;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photoId = look.person?.photoId;
    final member = look.member;
    if (photoId != null) {
      return SizedBox.square(
        dimension: size,
        child: NannyPhoto(
          photoId: photoId,
          label: NannyPickupCopy.photoOf(look.name),
          aspectRatio: 1,
        ),
      );
    }
    if (member != null) {
      return NestAvatar(
        name: member.displayName,
        color: member.color,
        size: size,
      );
    }
    return NestIconTile(
      icon: LucideIcons.user,
      tint: NestTileTint.lilac,
      size: size,
      iconSize: NestSize.iconMedium,
    );
  }
}
