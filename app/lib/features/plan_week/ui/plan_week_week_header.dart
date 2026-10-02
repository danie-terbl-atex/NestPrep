import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/plan_fallback.dart';
import '../model/shop_week.dart';

/// The top of the week step: who built it, how many AI calls are left, why
/// it was built without AI when it was, and what the server left out.
class PlanWeekWeekHeader extends StatelessWidget {
  const PlanWeekWeekHeader({required this.plan, super.key});

  final ShopWeek plan;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final reason = plan.fallbackReason;
    final calls = plan.callsLeft;
    final isAi = plan.source == PlanSource.ai;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(PlanWeekCopy.weekHeadline, style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.tapToSwap, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.md),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestTag(
              label: isAi
                  ? PlanWeekCopy.builtByAi
                  : PlanWeekCopy.builtWithoutAi,
              tone: isAi ? NestTagTone.accent : NestTagTone.neutral,
              icon: LucideIcons.sparkles,
            ),
            if (calls != null) NestTag(label: PlanWeekCopy.callsLeft(calls)),
          ],
        ),
        if (reason != null) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(message: PlanWeekCopy.fallbackWeek(reason)),
        ],
        if (plan.dropped > 0) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(
            message: PlanWeekCopy.dropped(plan.dropped),
            tone: NestBannerTone.warning,
          ),
        ],
      ],
    );
  }
}
