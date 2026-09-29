import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../model/home_care_board.dart';
import '../model/job_event.dart';
import 'job_status_tag.dart';

/// Everything that has happened to a job, oldest first: who assigned it,
/// when it was started, handed in, sent back — with the note — and
/// approved. Its own loading and error, so a slow history never holds up
/// the job above it (`FE-08`).
class JobHistory extends StatelessWidget {
  const JobHistory({
    required this.events,
    required this.board,
    required this.onRetry,
    super.key,
  });

  final AsyncState<List<JobEvent>> events;
  final HomeCareBoard board;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return switch (events) {
      AsyncLoading() => const NestSkeleton(),
      AsyncFailure(:final failure) => NestBanner(
        message: AppCopy.failure(failure),
        tone: NestBannerTone.danger,
        actionLabel: AppCopy.retry,
        onAction: onRetry,
      ),
      AsyncData(:final value) when value.isEmpty => Text(
        HomeCareCopy.historyEmpty,
        style: nest.text.caption,
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final event in value)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: _EventLine(event: event, board: board),
            ),
        ],
      ),
    };
  }
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.event, required this.board});

  final JobEvent event;
  final HomeCareBoard board;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final at = event.at;
    final who =
        board.memberById(event.by)?.displayName ?? HomeCareCopy.helperGone;
    final when = at == null
        ? HomeCareCopy.justNow
        : HomeCareCopy.dayAndTime(
            NestDates.relative(clock.dateOf(at), clock.today),
            NestDates.timeOfDay(clock.minutesOfDay(at)),
          );
    final note = event.note;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JobStatusTag(status: event.status),
        const SizedBox(width: NestSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(HomeCareCopy.byWhom(who), style: nest.text.label),
              Text(when, style: nest.text.caption),
              if (note != null) ...[
                const SizedBox(height: NestSpace.xs),
                Text(HomeCareCopy.quoted(note), style: nest.text.bodySecondary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
