import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/cleaning_job.dart';
import '../model/job_status.dart';
import '../model/safety/job_safety.dart';
import '../state/home_care_controller.dart';
import '../state/job_controller.dart';
import 'before_you_start.dart';
import 'big_step_tile.dart';
import 'job_board_view.dart';
import 'job_photo_view.dart';
import 'photo_capture_card.dart';
import 'step_progress_bar.dart';

/// The helper's step-through: the safety first, then each step as a big
/// tile she ticks as she goes, then the after photo and the hand-in
/// (home-care ADR-0001). A job she has already started opens on its steps.
class StepThroughScreen extends StatefulWidget {
  const StepThroughScreen({super.key});

  @override
  State<StepThroughScreen> createState() => _StepThroughScreenState();
}

class _StepThroughScreenState extends State<StepThroughScreen> {
  bool? _hasReadSafety;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JobController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: HomeCareCopy.stepThroughTitle,
      leading: backLeading(context),
      body: JobBoardView(
        builder: (context, board, job) {
          final hasRead = _hasReadSafety ?? job.status == JobStatus.inProgress;
          return ListView(
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
              if (!hasRead)
                BeforeYouStart(
                  safety: JobSafety.of(board.productsOf(job)),
                  onReady: () => setState(() => _hasReadSafety = true),
                )
              else
                _Steps(job: job, controller: controller),
            ],
          );
        },
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.job, required this.controller});

  final CleaningJob job;
  final JobController controller;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canWork = context.watch<HomeCareController>().access.canWork(job);
    final actions = controller.actions;
    final note = job.reviewNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(job.title, style: nest.text.headline),
        const SizedBox(height: NestSpace.md),
        StepProgressBar(
          progress: job.progress,
          height: NestSpace.md,
          label: HomeCareCopy.stepsDone(job.doneCount, job.steps.length),
        ),
        const SizedBox(height: NestSpace.lg),
        if (job.status == JobStatus.sentBack && note != null) ...[
          NestBanner(
            message: HomeCareCopy.sentBackWith(note),
            tone: NestBannerTone.warning,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        JobPhotoView(
          photo: job.beforePhoto,
          state: controller.photo(job.beforePhoto.photoId),
          marks: job.marks,
          semanticLabel: HomeCareCopy.beforePhoto,
          onRetry: () => controller.retryPhoto(job.beforePhoto.photoId),
        ),
        const SizedBox(height: NestSpace.xl),
        for (final (index, step) in job.steps.indexed) ...[
          BigStepTile(
            number: index + 1,
            text: step.text,
            isDone: job.isStepDone(step.id),
            onToggle: canWork ? () => actions.toggleStep(step.id) : null,
          ),
          const SizedBox(height: NestSpace.md),
        ],
        const SizedBox(height: NestSpace.lg),
        if (canWork && job.areAllStepsDone) ...[
          NestRiseIn(
            child: PhotoCaptureCard(
              photo: actions.afterPhoto,
              isBusy: actions.isTakingPhoto,
              prompt: HomeCareCopy.afterPrompt,
              promptBody: HomeCareCopy.afterPromptBody,
              semanticLabel: HomeCareCopy.afterPhoto,
              onTake: actions.takeAfterPhoto,
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: HomeCareCopy.handIn,
            icon: Icons.task_alt,
            isLoading: actions.isBusy,
            onPressed: actions.afterPhoto == null || actions.isBusy
                ? null
                : () => _handIn(context),
          ),
        ] else if (canWork)
          Text(
            HomeCareCopy.tickEveryStep,
            style: nest.text.caption,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Future<void> _handIn(BuildContext context) async {
    final isHandedIn = await controller.actions.handIn();
    if (isHandedIn && context.mounted) context.pop();
  }
}
