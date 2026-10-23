import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/ui/lunch_week_name.dart';
import '../model/shop_week.dart';

/// The top of the week step: which week it is — "Lunches for next week"
/// (lunch-box ADR-0019) — which days get a treat when the plan packs them
/// (Friday by ADR-0003, or the brief's treat days by ADR-0025), why it was
/// built on the phone when it was, and what the server left out.
class PlanWeekWeekHeader extends StatelessWidget {
  const PlanWeekWeekHeader({
    required this.plan,
    required this.weekName,
    super.key,
  });

  final ShopWeek plan;
  final LunchWeekName weekName;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final reason = plan.fallbackReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PlanWeekCopy.weekHeadline(weekName.inSentence),
          style: nest.text.headline,
        ),
        const SizedBox(height: NestSpace.xs),
        Text(PlanWeekCopy.tapToSwap, style: nest.text.bodySecondary),
        if (plan.slots.contains(LunchSlot.treat) &&
            plan.treatDays.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xs),
          Text(PlanWeekCopy.treatsOn(plan.treatDays), style: nest.text.caption),
        ],
        if (reason != null) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(
            message: plan.searches.any((search) => search.isDish)
                ? '${PlanWeekCopy.fallbackWeek(reason)} '
                      '${PlanWeekCopy.dishesNeedAi}'
                : PlanWeekCopy.fallbackWeek(reason),
          ),
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
