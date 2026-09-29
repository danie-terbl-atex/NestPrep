import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/home_care_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_board.dart';
import '../model/job_status.dart';
import '../state/home_care_controller.dart';
import '../state/job_controller.dart';
import 'job_edit_sheet.dart';

/// What this person can do next with this job, and nothing they cannot:
/// the helper starts or carries on, a parent reviews what was handed in, and
/// changes or removes a job while it is still with the helper (`FE-04`).
class JobNextStep extends StatelessWidget {
  const JobNextStep({required this.job, required this.board, super.key});

  final CleaningJob job;
  final HomeCareBoard board;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCareController>();
    final controller = context.watch<JobController>();
    final access = home.access;
    final isBusy = controller.actions.isBusy;
    final householdId = home.householdId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (access.canWork(job))
          NestButton(
            label: switch (job.status) {
              JobStatus.inProgress => HomeCareCopy.carryOn,
              JobStatus.sentBack => HomeCareCopy.tryAgain,
              _ => HomeCareCopy.start,
            },
            icon: Icons.play_arrow_rounded,
            onPressed: () =>
                context.push(HomeCareRoute.stepsPathFor(householdId, job.id)),
          ),
        if (access.canReview(job))
          NestButton(
            label: HomeCareCopy.review,
            icon: Icons.compare_outlined,
            onPressed: () =>
                context.push(HomeCareRoute.reviewPathFor(householdId, job.id)),
          ),
        if (job.status.isWaitingForReview && !access.canManage)
          const NestBanner(message: HomeCareCopy.waitingForReview),
        if (access.canChangeDetails(job)) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: HomeCareCopy.editJob,
            icon: Icons.edit_outlined,
            variant: NestButtonVariant.tonal,
            onPressed: isBusy ? null : () => _edit(context, home, controller),
          ),
        ],
        if (access.canManage) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: HomeCareCopy.deleteJob,
            icon: Icons.delete_outline,
            variant: NestButtonVariant.ghost,
            isLoading: isBusy,
            onPressed: isBusy ? null : () => _delete(context, controller),
          ),
        ],
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    HomeCareController home,
    JobController controller,
  ) async {
    final details = await showJobEditSheet(
      context: context,
      job: job,
      board: board,
      helpers: home.helpers,
    );
    if (details != null) await controller.actions.updateDetails(details);
  }

  static Future<void> _delete(
    BuildContext context,
    JobController controller,
  ) async {
    final isSure = await showNestConfirm(
      context: context,
      title: HomeCareCopy.deleteJobConfirm,
      message: HomeCareCopy.deleteJobBody,
      confirmLabel: HomeCareCopy.deleteJob,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (!(isSure ?? false)) return;
    final isDeleted = await controller.actions.delete();
    if (isDeleted && context.mounted) context.pop();
  }
}
