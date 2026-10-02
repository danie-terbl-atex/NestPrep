import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_board.dart';
import 'due_tag.dart';
import 'job_status_tag.dart';
import 'room_kind_look.dart';
import 'step_progress_bar.dart';

/// The facts of a job at a glance: its status, when it is due, the room,
/// who is doing it, how far along it is, and the parent's note.
class JobSummaryCard extends StatelessWidget {
  const JobSummaryCard({required this.job, required this.board, super.key});

  final CleaningJob job;
  final HomeCareBoard board;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final room = board.roomById(job.roomId);
    final helper = board.memberById(job.helperId);
    final note = job.note;
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              JobStatusTag(status: job.status),
              if (!job.status.isDone) DueTag(job: job),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          NestListRow(
            title: room?.name ?? HomeCareCopy.roomGone,
            subtitle: HomeCareCopy.room,
            leading: NestIconTile(
              icon: room?.kind.icon ?? LucideIcons.doorClosed,
              tint: room?.kind.tint ?? NestTileTint.accent,
              size: NestSize.avatarMedium,
              iconSize: NestSize.iconMedium,
            ),
          ),
          NestListRow(
            title: helper?.displayName ?? HomeCareCopy.helperGone,
            subtitle: HomeCareCopy.helper,
            leading: helper == null
                ? const NestIconTile(
                    icon: LucideIcons.userX,
                    size: NestSize.avatarMedium,
                    iconSize: NestSize.iconMedium,
                  )
                : NestAvatar(name: helper.displayName, color: helper.color),
          ),
          const SizedBox(height: NestSpace.sm),
          StepProgressBar(
            progress: job.progress,
            label: HomeCareCopy.stepsDone(job.doneCount, job.steps.length),
          ),
          if (note != null) ...[
            const SizedBox(height: NestSpace.md),
            Text(HomeCareCopy.quoted(note), style: nest.text.bodySecondary),
          ],
        ],
      ),
    );
  }
}
