import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/cleaning_job.dart';
import 'step_number.dart';

/// A job's checklist to read — ticked where it is done. Ticking is the
/// step-through's, where the targets are big enough to hit with wet hands.
class JobStepsList extends StatelessWidget {
  const JobStepsList({required this.job, this.textFor, super.key});

  final CleaningJob job;

  /// A step as the viewer reads it — in her own language on her screens
  /// (home-care ADR-0006); the step as written when null.
  final String Function(String english)? textFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, step) in job.steps.indexed)
          Semantics(
            label: HomeCareCopy.stepForReader(
              index + 1,
              textFor?.call(step.text) ?? step.text,
              isDone: job.isStepDone(step.id),
            ),
            excludeSemantics: true,
            child: NestListRow(
              title: textFor?.call(step.text) ?? step.text,
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
