import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/shop_week.dart';

/// The top of the week step: why it was built on the phone when it was, and
/// what the server left out.
class PlanWeekWeekHeader extends StatelessWidget {
  const PlanWeekWeekHeader({required this.plan, super.key});

  final ShopWeek plan;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final reason = plan.fallbackReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(PlanWeekCopy.weekHeadline, style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.tapToSwap, style: nest.text.bodySecondary),
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
