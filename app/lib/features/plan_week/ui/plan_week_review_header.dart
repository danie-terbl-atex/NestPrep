import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/planned_week.dart';

/// The top of the review: the headline, how much is ready, who planned it —
/// the model, or the app on its own and why — and, after an AI plan, how
/// many are left this month.
class PlanWeekReviewHeader extends StatelessWidget {
  const PlanWeekReviewHeader({required this.planned, super.key});

  final PlannedWeek planned;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final reason = planned.fallbackReason;
    final callsLeft = planned.callsLeft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(PlanWeekCopy.reviewTitle, style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(
          PlanWeekCopy.reviewSummary(
            planned.lunchCount,
            planned.dinners.length,
          ),
          style: nest.text.bodySecondary,
        ),
        const SizedBox(height: NestSpace.md),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            switch (planned.source) {
              PlanSource.ai => const NestTag(
                label: PlanWeekCopy.madeByAi,
                tone: NestTagTone.accent,
                icon: Icons.auto_awesome_rounded,
              ),
              PlanSource.fallback => const NestTag(
                label: PlanWeekCopy.madeWithoutAi,
                icon: Icons.favorite_border_rounded,
              ),
            },
            if (callsLeft != null)
              Text(PlanWeekCopy.callsLeft(callsLeft), style: nest.text.caption),
          ],
        ),
        if (reason != null) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(message: PlanWeekCopy.fallbackBody(reason)),
        ],
        if (planned.dropped > 0) ...[
          const SizedBox(height: NestSpace.sm),
          Text(PlanWeekCopy.dropped(planned.dropped), style: nest.text.caption),
        ],
        const SizedBox(height: NestSpace.sm),
        Text(PlanWeekCopy.tapToSwap, style: nest.text.caption),
      ],
    );
  }
}
