import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../model/cleaning_job.dart';

/// When a job is due, in the household's own words for the day — and,
/// once the day has passed with the job still open, that it is late.
class DueTag extends StatelessWidget {
  const DueTag({required this.job, super.key});

  final CleaningJob job;

  @override
  Widget build(BuildContext context) {
    final today = context.read<HouseholdClock>().today;
    final day = NestDates.relative(job.dueDate, today);
    final isLate = job.isOverdue(today);
    return NestTag(
      label: isLate ? HomeCareCopy.overdue(day) : HomeCareCopy.due(day),
      icon: isLate ? Icons.schedule : Icons.event_outlined,
      tone: isLate ? NestTagTone.danger : NestTagTone.neutral,
    );
  }
}
