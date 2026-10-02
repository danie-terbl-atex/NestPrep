import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../state/home_care_controller.dart';
import '../state/job_controller.dart';
import 'before_and_after.dart';
import 'job_board_view.dart';
import 'job_steps_list.dart';
import 'send_back_sheet.dart';

/// The parent's review: before and after side by side, the checklist as
/// the helper left it, and two ways out — approve it, or send it back with
/// a note she will read (home-care ADR-0001).
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JobController>();
    final access = context.watch<HomeCareController>().access;
    final failure = controller.actionFailure;
    final isBusy = controller.actions.isBusy;
    return NestScaffold(
      title: HomeCareCopy.reviewTitle,
      leading: backLeading(context),
      body: JobBoardView(
        builder: (context, board, job) {
          final helper = board.memberById(job.helperId)?.displayName;
          final canReview = access.canReview(job);
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
              Text(job.title, style: NestTheme.of(context).text.headline),
              Text(
                HomeCareCopy.handedInBy(helper ?? HomeCareCopy.helperGone),
                style: NestTheme.of(context).text.bodySecondary,
              ),
              const SizedBox(height: NestSpace.lg),
              BeforeAndAfter(job: job, controller: controller),
              const SizedBox(height: NestSpace.xl),
              const NestSectionHeader(title: HomeCareCopy.steps),
              JobStepsList(job: job),
              const SizedBox(height: NestSpace.xl),
              if (canReview) ...[
                NestButton(
                  label: HomeCareCopy.approve,
                  icon: LucideIcons.badgeCheck,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : () => _approve(context),
                ),
                const SizedBox(height: NestSpace.sm),
                NestButton(
                  label: HomeCareCopy.sendBack,
                  icon: LucideIcons.rotateCcw,
                  variant: NestButtonVariant.outline,
                  onPressed: isBusy ? null : () => _sendBack(context),
                ),
              ] else
                const NestBanner(message: HomeCareCopy.nothingToReview),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _approve(BuildContext context) async {
    final isDone = await context.read<JobController>().actions.approve();
    if (isDone && context.mounted) context.pop();
  }

  static Future<void> _sendBack(BuildContext context) async {
    final note = await showSendBackSheet(context);
    if (note == null || !context.mounted) return;
    final isDone = await context.read<JobController>().actions.sendBack(note);
    if (isDone && context.mounted) context.pop();
  }
}
