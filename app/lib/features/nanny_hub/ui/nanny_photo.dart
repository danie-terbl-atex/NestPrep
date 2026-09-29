import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/photo_library.dart';

/// One hub photo, by its id, at a fixed shape so a list never jumps as photos
/// arrive (`FE-18`): a placeholder while it loads, a quiet "did not load"
/// with a retry when it failed, the picture when it is there. It never
/// fetches — the controller asked the library for it (`FE-05`).
class NannyPhoto extends StatelessWidget {
  const NannyPhoto({
    required this.photoId,
    required this.label,
    this.aspectRatio = 4 / 3,
    super.key,
  });

  final String photoId;

  /// What the photo shows, for somebody who cannot see it (`FE-13`).
  final String label;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final library = context.watch<PhotoLibrary>();
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NestRadius.lg),
        child: switch (library.stateOf(photoId)) {
          AsyncLoading() => Semantics(
            label: NannyCopy.photoLoading,
            child: const NestSkeleton(height: double.infinity),
          ),
          AsyncFailure() => ColoredBox(
            color: nest.colors.surfaceTint,
            // A thumbnail is small, and at a large text setting the words
            // would not fit it; they shrink rather than overflow (`FE-14`).
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    NannyCopy.photoFailed,
                    style: nest.text.caption,
                    textAlign: TextAlign.center,
                  ),
                  NestIconButton(
                    icon: Icons.refresh,
                    label: AppCopy.retry,
                    variant: NestIconButtonVariant.plain,
                    onPressed: () => library.retry(photoId),
                  ),
                ],
              ),
            ),
          ),
          AsyncData(:final value) => Semantics(
            image: true,
            label: label,
            child: Image.memory(
              value,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          ),
        },
      ),
    );
  }
}
