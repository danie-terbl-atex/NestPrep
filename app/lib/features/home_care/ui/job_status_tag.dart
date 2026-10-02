import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/job_status.dart';

/// A job's status as a tag: its word, its icon and its tone — the word is
/// the signal, the colour only agrees with it (`FE-13`).
class JobStatusTag extends StatelessWidget {
  const JobStatusTag({required this.status, super.key});

  final JobStatus status;

  @override
  Widget build(BuildContext context) => NestTag(
    label: HomeCareCopy.status(status),
    icon: switch (status) {
      JobStatus.assigned => LucideIcons.badgePlus,
      JobStatus.inProgress => LucideIcons.loaderCircle,
      JobStatus.submitted => LucideIcons.camera,
      JobStatus.approved => LucideIcons.badgeCheck,
      JobStatus.sentBack => LucideIcons.rotateCcw,
    },
    tone: switch (status) {
      JobStatus.assigned => NestTagTone.accent,
      JobStatus.inProgress => NestTagTone.neutral,
      JobStatus.submitted => NestTagTone.warning,
      JobStatus.approved => NestTagTone.success,
      JobStatus.sentBack => NestTagTone.danger,
    },
  );
}
