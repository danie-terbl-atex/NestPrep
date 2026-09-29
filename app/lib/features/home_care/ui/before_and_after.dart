import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/cleaning_job.dart';
import '../state/job_controller.dart';
import 'job_photo_view.dart';

/// The spot as it was, circled, beside the spot as it is now — side by side
/// where there is room, one above the other where there is not, each
/// labelled in words so the order is never only a position (`FE-13`).
class BeforeAndAfter extends StatelessWidget {
  const BeforeAndAfter({
    required this.job,
    required this.controller,
    super.key,
  });

  final CleaningJob job;
  final JobController controller;

  /// Below this width two photos side by side are too small to judge a
  /// stain by.
  static const _sideBySideFrom = 320.0;

  @override
  Widget build(BuildContext context) {
    final after = job.afterPhoto;
    final before = _Labelled(
      label: HomeCareCopy.before,
      child: JobPhotoView(
        photo: job.beforePhoto,
        state: controller.photo(job.beforePhoto.photoId),
        marks: job.marks,
        semanticLabel: HomeCareCopy.beforePhoto,
        onRetry: () => controller.retryPhoto(job.beforePhoto.photoId),
      ),
    );
    final afterView = _Labelled(
      label: HomeCareCopy.after,
      child: after == null
          ? const NestSkeleton(height: NestSize.previewHeight)
          : JobPhotoView(
              photo: after,
              frameAspectRatio: job.beforePhoto.aspectRatio,
              state: controller.photo(after.photoId),
              semanticLabel: HomeCareCopy.afterPhoto,
              onRetry: () => controller.retryPhoto(after.photoId),
            ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _sideBySideFrom ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              before,
              const SizedBox(height: NestSpace.lg),
              afterView,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: before),
            const SizedBox(width: NestSpace.md),
            Expanded(child: afterView),
          ],
        );
      },
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: NestTag(label: label),
      ),
      const SizedBox(height: NestSpace.sm),
      child,
    ],
  );
}
