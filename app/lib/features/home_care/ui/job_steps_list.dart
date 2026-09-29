import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/cleaning_job.dart';
import 'step_number.dart';

/// A job's checklist to read — ticked where it is done. Ticking is the
/// step-through's, where the targets are big enough to hit with wet hands.
class JobStepsList extends StatelessWidget {
  const JobStepsList({required this.job, super.key});

  final CleaningJob job;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, step) in job.steps.indexed)
          Semantics(
            label: HomeCareCopy.stepForReader(
              index + 1,
              step.text,
              isDone: job.isStepDone(step.id),
            ),
            excludeSemantics: true,
            child: NestListRow(
              title: step.text,
              leading: StepNumber(
                number: index + 1,
                isDone: job.isStepDone(step.id),
              ),
            ),
          ),
      ],
    );
  }
}
