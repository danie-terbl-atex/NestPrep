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
      JobStatus.assigned => Icons.fiber_new_outlined,
      JobStatus.inProgress => Icons.timelapse,
      JobStatus.submitted => Icons.photo_camera_outlined,
      JobStatus.approved => Icons.verified_outlined,
      JobStatus.sentBack => Icons.replay,
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
