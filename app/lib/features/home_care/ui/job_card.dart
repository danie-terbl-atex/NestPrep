import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_room.dart';
import '../model/job_status.dart';
import 'due_tag.dart';
import 'job_status_tag.dart';
import 'room_kind_look.dart';
import 'step_progress_bar.dart';

/// One job in a list: where, what, who, when, and how far along.
class JobCard extends StatelessWidget {
  const JobCard({
    required this.job,
    required this.room,
    required this.helper,
    required this.onTap,
    super.key,
  });

  final CleaningJob job;

  /// Null when the room has since been deleted.
  final HomeCareRoom? room;

  /// Null when the helper has left the household.
  final Member? helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final where = room?.name ?? HomeCareCopy.roomGone;
    final who = helper?.displayName ?? HomeCareCopy.helperGone;
    return NestCard(
      onTap: onTap,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NestIconTile(
                icon: room?.kind.icon ?? Icons.cleaning_services_outlined,
                tint: room?.kind.tint ?? NestTileTint.accent,
                size: NestSize.avatarLarge,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: nest.text.bodyStrong),
                    const SizedBox(height: NestSpace.xxs),
                    Text(
                      HomeCareCopy.whereAndWho(where, who),
                      style: nest.text.caption,
                    ),
                  ],
                ),
              ),
              if (helper case final member?) ...[
                const SizedBox(width: NestSpace.sm),
                NestAvatar(
                  name: member.displayName,
                  color: member.color,
                  size: NestSize.avatarSmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              JobStatusTag(status: job.status),
              if (!job.status.isDone) DueTag(job: job),
            ],
          ),
          if (job.status == JobStatus.inProgress) ...[
            const SizedBox(height: NestSpace.md),
            StepProgressBar(
              progress: job.progress,
              label: HomeCareCopy.stepsDone(job.doneCount, job.steps.length),
            ),
          ],
        ],
      ),
    );
  }
}
