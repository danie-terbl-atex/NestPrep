import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../model/referral_overview.dart';
import '../model/referral_status.dart';
import '../state/referral_controller.dart';
import 'redeem_code_card.dart';
import 'referral_code_card.dart';
import 'referral_hero.dart';
import 'referral_how_it_works.dart';
import 'referral_line_row.dart';
import 'referral_months_card.dart';

/// The referral screen once its three listeners have answered: the promise,
/// the household's code, its free months, the way to enter another family's
/// code while it still may, how it works, and every referral so far
/// (subscriptions ADR-0002). An empty history is said in place, under the
/// code that fills it (`FE-08`).
class ReferralBody extends StatelessWidget {
  const ReferralBody({required this.overview, super.key});

  final ReferralOverview overview;

  /// The stagger stops after the first screenful (design-system ADR-0002).
  static const _staggered = 4;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReferralController>();
    final clock = context.read<HouseholdClock>();
    final now = controller.now();
    String dateOf(DateTime instant) =>
        NestDates.full(clock.dateOf(instant), clock.today);

    final referral = overview.referral;
    final running = overview.runningAt(now)?.endsAt;
    final redeemBy = referral.redeemBy;
    final joined = overview.joinedWith;
    final redeemFailure = controller.redeemFailure;
    final sections = <Widget>[
      const ReferralHero(),
      ReferralCodeCard(
        code: referral.code,
        isMakingCode: controller.isMakingCode,
        codeFailure: controller.codeFailure,
        onShare: () => unawaited(controller.share()),
        onRetry: () => unawaited(controller.retryCode()),
      ),
      ReferralMonthsCard(
        earnedThisYear: overview.monthsThisYear(now),
        yearlyCap: referral.yearlyRewardCap,
        runningUntilLabel: running == null ? null : dateOf(running),
        monthsWaiting: overview.monthsWaiting,
        hasReachedCap: overview.hasReachedCapAt(now),
      ),
      if (redeemBy != null && referral.canRedeemAt(now))
        RedeemCodeCard(
          deadlineLabel: dateOf(redeemBy),
          isBusy: controller.isRedeeming,
          errorText: redeemFailure == null
              ? null
              : AppCopy.failure(redeemFailure),
          onSubmit: (code) => unawaited(controller.redeem(code)),
          onEdited: controller.clearRedeemFailure,
        )
      else if (joined != null && joined.statusAt(now) == ReferralStatus.pending)
        NestBanner(
          message: ReferralCopy.redeemed(dateOf(joined.qualifyBy ?? now)),
          tone: NestBannerTone.success,
        ),
      const ReferralHowItWorks(),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (controller.shareUnavailable) ...[
          const NestBanner(
            message: ReferralCopy.shareUnavailable,
            tone: NestBannerTone.warning,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        for (final (index, section) in sections.indexed) ...[
          NestRiseIn(index: index.clamp(0, _staggered), child: section),
          const SizedBox(height: NestSpace.lg),
        ],
        const NestSectionHeader(title: ReferralCopy.historyTitle),
        const SizedBox(height: NestSpace.sm),
        if (overview.lines.isEmpty)
          Text(
            ReferralCopy.historyEmpty,
            style: NestTheme.of(context).text.bodySecondary,
          )
        else
          for (final line in overview.lines)
            Padding(
              key: ValueKey(line.id),
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: ReferralLineRow(line: line, now: now, formatDate: dateOf),
            ),
      ],
    );
  }
}
