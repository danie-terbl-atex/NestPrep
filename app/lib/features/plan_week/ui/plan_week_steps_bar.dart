import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/plan_week_controller.dart';

/// Where in the five steps the parent is: a segment per step, filled up to
/// this one, and the step's name in words — the words carry it, the bar is
/// the glance (`FE-13`).
class PlanWeekStepsBar extends StatelessWidget {
  const PlanWeekStepsBar({required this.step, super.key});

  final PlanWeekStep step;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final number = step.index + 1;
    final name = PlanWeekCopy.stepNames[step.index];
    return Semantics(
      label: PlanWeekCopy.stepOf(number, name),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final each in PlanWeekStep.values) ...[
                if (each.index > 0) const SizedBox(width: NestSpace.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: NestMotion.of(context).standard,
                    height: NestSpace.xs,
                    decoration: BoxDecoration(
                      color: each.index <= step.index
                          ? nest.colors.accent
                          : nest.colors.surfaceTint,
                      borderRadius: BorderRadius.circular(NestRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(PlanWeekCopy.stepOf(number, name), style: nest.text.caption),
        ],
      ),
    );
  }
}
