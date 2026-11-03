import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import '../state/frame_photos_controller.dart';

class FrameAlbumCard extends StatelessWidget {
  const FrameAlbumCard({
    required this.controller,
    required this.onTap,
    super.key,
  });

  final FramePhotosController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: PhotoFrameCopy.photosTitle,
        subtitle: !controller.isLoaded
            ? PhotoFrameCopy.albumEntryBody
            : controller.isEmpty
            ? PhotoFrameCopy.albumEntryEmpty
            : PhotoFrameCopy.photoCount(controller.count),
        leading: const NestIconTile(
          icon: LucideIcons.images,
          tint: NestTileTint.lilac,
        ),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}
