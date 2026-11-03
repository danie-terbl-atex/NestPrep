import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/frame_photo.dart';
import '../state/frame_photos_controller.dart';

class FramePhotoTile extends StatefulWidget {
  const FramePhotoTile({
    required this.photo,
    required this.position,
    required this.controller,
    required this.onTap,
    super.key,
  });

  final FramePhoto photo;
  final int position;
  final FramePhotosController controller;
  final VoidCallback? onTap;

  @override
  State<FramePhotoTile> createState() => _FramePhotoTileState();
}

class _FramePhotoTileState extends State<FramePhotoTile> {
  @override
  void initState() {
    super.initState();
    widget.controller.ensureThumbnail(widget.photo.id);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = widget.controller;
    final photoId = widget.photo.id;
    final isRemoving = controller.removingId == photoId;
    final onTap = widget.onTap;
    return ClipRRect(
      borderRadius: BorderRadius.circular(NestRadius.md),
      child: switch (controller.thumbnailOf(photoId)) {
        AsyncLoading() => Semantics(
          label: PhotoFrameCopy.photoLoading,
          child: const NestSkeleton(height: double.infinity),
        ),
        AsyncFailure() => ColoredBox(
          color: nest.colors.surfaceTint,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  PhotoFrameCopy.photoFailed,
                  style: nest.text.caption,
                  textAlign: TextAlign.center,
                ),
                NestIconButton(
                  icon: LucideIcons.refreshCw,
                  label: AppCopy.retry,
                  variant: NestIconButtonVariant.plain,
                  onPressed: () => controller.retryThumbnail(photoId),
                ),
              ],
            ),
          ),
        ),
        AsyncData(:final value) => Semantics(
          button: true,
          image: true,
          label: PhotoFrameCopy.photoLabel(widget.position),
          hint: PhotoFrameCopy.removePhoto,
          child: NestPressable(
            enabled: onTap != null,
            child: GestureDetector(
              onTap: onTap,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      value,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                      cacheWidth:
                          (constraints.maxWidth *
                                  MediaQuery.devicePixelRatioOf(context))
                              .round(),
                    ),
                    if (isRemoving)
                      ColoredBox(
                        color: nest.colors.surface.withValues(alpha: 0.6),
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      },
    );
  }
}
