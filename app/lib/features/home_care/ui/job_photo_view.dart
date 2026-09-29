import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/job_photo.dart';
import '../model/spot_mark.dart';
import 'marked_photo.dart';

/// One of a job's stored photos, in all four of its states: a frame of the
/// right shape while it loads, the photo, or words and a retry when it could
/// not be read (`FE-08`, `FE-09`).
class JobPhotoView extends StatelessWidget {
  const JobPhotoView({
    required this.photo,
    required this.state,
    required this.semanticLabel,
    required this.onRetry,
    this.marks = const [],
    this.frameAspectRatio,
    super.key,
  });

  final JobPhoto photo;
  final AsyncState<Uint8List> state;
  final String semanticLabel;
  final VoidCallback onRetry;
  final List<SpotMark> marks;

  /// A frame of another shape, filled by the photo — for an after photo
  /// shown beside a before photo, so the two are the same size. Only a photo
  /// with no circles on it may be cropped like this.
  final double? frameAspectRatio;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final aspectRatio = frameAspectRatio ?? photo.aspectRatio;
    return switch (state) {
      AsyncData(:final value) => MarkedPhoto(
        bytes: value,
        aspectRatio: aspectRatio,
        marks: marks,
        semanticLabel: semanticLabel,
      ),
      AsyncLoading() => AspectRatio(
        aspectRatio: aspectRatio,
        child: const NestSkeleton(height: double.infinity),
      ),
      AsyncFailure(:final failure) => AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: nest.colors.surfaceTint,
            borderRadius: BorderRadius.circular(NestRadius.lg),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NestSpace.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppCopy.failure(failure),
                    style: nest.text.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: NestSpace.sm),
                  NestButton(
                    label: AppCopy.retry,
                    variant: NestButtonVariant.tonal,
                    size: NestButtonSize.small,
                    isExpanded: false,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    };
  }
}
