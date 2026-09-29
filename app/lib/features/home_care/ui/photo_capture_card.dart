import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../data/photo_source.dart';
import '../model/spot_mark.dart';
import 'marked_photo.dart';

/// A photo still to be taken, or the one that was: take it with the camera
/// or choose it from the phone, and — for a before photo — circle the spot.
/// The composer's before photo and the helper's after photo both use it.
class PhotoCaptureCard extends StatelessWidget {
  const PhotoCaptureCard({
    required this.photo,
    required this.isBusy,
    required this.prompt,
    required this.promptBody,
    required this.semanticLabel,
    required this.onTake,
    this.marks = const [],
    this.onMark,
    super.key,
  });

  final CompressedPhoto? photo;
  final bool isBusy;
  final String prompt;
  final String promptBody;
  final String semanticLabel;
  final ValueChanged<PhotoOrigin> onTake;
  final List<SpotMark> marks;

  /// Null for a photo nobody circles on.
  final VoidCallback? onMark;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final taken = photo;
    final mark = onMark;
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (taken == null) ...[
            const NestIconTile(
              icon: Icons.add_a_photo_outlined,
              tint: NestTileTint.peach,
              size: NestSize.mark,
              iconSize: NestSize.iconMark,
            ),
            const SizedBox(height: NestSpace.md),
            Text(prompt, style: nest.text.title, textAlign: TextAlign.center),
            const SizedBox(height: NestSpace.xs),
            Text(
              promptBody,
              style: nest.text.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ] else
            MarkedPhoto(
              bytes: taken.bytes,
              aspectRatio: taken.width / taken.height,
              marks: marks,
              semanticLabel: semanticLabel,
            ),
          const SizedBox(height: NestSpace.lg),
          if (taken != null && mark != null) ...[
            NestButton(
              label: marks.isEmpty
                  ? HomeCareCopy.markSpot
                  : HomeCareCopy.markAgain,
              icon: Icons.gesture,
              onPressed: isBusy ? null : mark,
            ),
            const SizedBox(height: NestSpace.sm),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestButton(
                label: taken == null
                    ? HomeCareCopy.takePhoto
                    : HomeCareCopy.retakePhoto,
                icon: Icons.photo_camera_outlined,
                variant: taken == null
                    ? NestButtonVariant.primary
                    : NestButtonVariant.tonal,
                size: NestButtonSize.medium,
                isExpanded: false,
                isLoading: isBusy,
                onPressed: isBusy ? null : () => onTake(PhotoOrigin.camera),
              ),
              NestButton(
                label: HomeCareCopy.choosePhoto,
                icon: Icons.photo_library_outlined,
                variant: NestButtonVariant.outline,
                size: NestButtonSize.medium,
                isExpanded: false,
                onPressed: isBusy ? null : () => onTake(PhotoOrigin.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
