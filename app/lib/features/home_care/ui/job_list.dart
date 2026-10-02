import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_access.dart';
import '../model/home_care_board.dart';
import 'job_card.dart';
import 'job_pile_chips.dart';

/// The piles and the jobs in the chosen one. An empty pile says so where
/// its jobs would be, under the piles, which stay (`FE-08`).
class JobList extends StatelessWidget {
  const JobList({
    required this.board,
    required this.pile,
    required this.access,
    required this.onSelectPile,
    required this.onOpen,
    this.header,
    super.key,
  });

  /// Above the piles — the ways into routines, stock and languages.
  final Widget? header;

  final HomeCareBoard board;
  final JobPile pile;
  final HomeCareAccess access;
  final ValueChanged<JobPile> onSelectPile;
  final ValueChanged<CleaningJob> onOpen;

  @override
  Widget build(BuildContext context) {
    final jobs = board.jobsIn(pile);
    return CustomScrollView(
      slivers: [
        if (header case final Widget top) SliverToBoxAdapter(child: top),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: JobPileChips(
              selected: pile,
              counts: {for (final p in JobPile.values) p: board.countIn(p)},
              onSelect: onSelectPile,
            ),
          ),
        ),
        if (jobs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: NestEmptyView(
              title: HomeCareCopy.emptyTitle(pile, isHelper: !access.canManage),
              message: HomeCareCopy.emptyBody(
                pile,
                isHelper: !access.canManage,
              ),
              icon: LucideIcons.sprayCan,
            ),
          )
        else
          SliverList.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(height: NestSpace.md),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return NestRiseIn(
                key: ValueKey(job.id),
                index: index.clamp(0, 6),
                child: JobCard(
                  job: job,
                  room: board.roomById(job.roomId),
                  helper: board.memberById(job.helperId),
                  onTap: () => onOpen(job),
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: NestSpace.huge)),
      ],
    );
  }
}
