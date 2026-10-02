import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_board.dart';
import '../state/home_care_controller.dart';
import '../state/job_controller.dart';

/// The four states every one-job screen shares: the board loading, failing,
/// the job gone — deleted while somebody was looking — or the job itself.
class JobBoardView extends StatelessWidget {
  const JobBoardView({required this.builder, super.key});

  final Widget Function(
    BuildContext context,
    HomeCareBoard board,
    CleaningJob job,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCareController>();
    final jobId = context.read<JobController>().jobId;
    return NestAsyncView<HomeCareBoard>(
      state: home.board,
      isEmpty: (board) => board.jobById(jobId) == null,
      onRetry: home.retry,
      emptyBuilder: (_) => const NestEmptyView(
        title: HomeCareCopy.jobGoneTitle,
        message: HomeCareCopy.jobGoneBody,
        icon: LucideIcons.sprayCan,
      ),
      dataBuilder: (context, board) =>
          builder(context, board, board.jobById(jobId)!),
    );
  }
}
