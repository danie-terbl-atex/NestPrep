import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_board.dart';
import '../model/job_status.dart';
import '../model/safety/job_safety.dart';
import '../state/job_controller.dart';
import 'job_board_view.dart';
import 'job_history.dart';
import 'job_next_step.dart';
import 'job_photo_view.dart';
import 'job_products_list.dart';
import 'job_steps_list.dart';
import 'job_summary_card.dart';
import 'safety_panel.dart';

/// One cleaning job: the spot, circled; where, who and when; the send-back
/// note if there is one; the safety first, then the products and the steps;
/// the after photo once handed in; and everything that has happened to it.
class JobScreen extends StatelessWidget {
  const JobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JobController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: HomeCareCopy.jobTitleScreen,
      leading: backLeading(context),
      body: JobBoardView(
        builder: (context, board, job) => ListView(
          padding: const EdgeInsets.only(bottom: NestSpace.huge),
          children: [
            if (failure != null) ...[
              NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
              const SizedBox(height: NestSpace.lg),
            ],
            Text(job.title, style: NestTheme.of(context).text.headline),
            const SizedBox(height: NestSpace.lg),
            JobPhotoView(
              photo: job.beforePhoto,
              state: controller.photo(job.beforePhoto.photoId),
              marks: job.marks,
              semanticLabel: HomeCareCopy.beforePhoto,
              onRetry: () => controller.retryPhoto(job.beforePhoto.photoId),
            ),
            const SizedBox(height: NestSpace.lg),
            if (JobSafety.of(board.productsOf(job)).hasDangers) ...[
              const NestBanner(
                message: HomeCareSafetyCopy.jobHasDangers,
                tone: NestBannerTone.danger,
              ),
              const SizedBox(height: NestSpace.lg),
            ],
            if (job.status == JobStatus.sentBack && job.reviewNote != null) ...[
              NestBanner(
                message: HomeCareCopy.sentBackWith(job.reviewNote ?? ''),
                tone: NestBannerTone.warning,
              ),
              const SizedBox(height: NestSpace.lg),
            ],
            JobSummaryCard(job: job, board: board),
            const SizedBox(height: NestSpace.xl),
            JobNextStep(job: job, board: board),
            _JobSections(job: job, board: board, controller: controller),
          ],
        ),
      ),
    );
  }
}

class _JobSections extends StatelessWidget {
  const _JobSections({
    required this.job,
    required this.board,
    required this.controller,
  });

  final CleaningJob job;
  final HomeCareBoard board;
  final JobController controller;

  @override
  Widget build(BuildContext context) {
    final products = board.productsOf(job);
    final after = job.afterPhoto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NestSpace.xxl),
        const NestSectionHeader(title: HomeCareSafetyCopy.title),
        const SizedBox(height: NestSpace.sm),
        SafetyPanel(safety: JobSafety.of(products)),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: HomeCareCopy.productsToUse),
        JobProductsList(products: products),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: HomeCareCopy.steps),
        JobStepsList(job: job),
        if (after != null) ...[
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: HomeCareCopy.afterPhoto),
          const SizedBox(height: NestSpace.sm),
          JobPhotoView(
            photo: after,
            state: controller.photo(after.photoId),
            semanticLabel: HomeCareCopy.afterPhoto,
            onRetry: () => controller.retryPhoto(after.photoId),
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: HomeCareCopy.history),
        const SizedBox(height: NestSpace.sm),
        JobHistory(
          events: controller.events,
          board: board,
          onRetry: controller.retryHistory,
        ),
      ],
    );
  }
}
