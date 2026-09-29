import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/referral_copy.dart';
import 'month_tokens.dart';

/// The free months the household has earned this year against the yearly
/// limit, and what is running or waiting now (subscriptions ADR-0002). A
/// month earned while the screen is open lands with a little burst of stars;
/// the sentence under it says the same in words (`FE-15`).
class ReferralMonthsCard extends StatelessWidget {
  const ReferralMonthsCard({
    required this.earnedThisYear,
    required this.yearlyCap,
    required this.runningUntilLabel,
    required this.monthsWaiting,
    required this.hasReachedCap,
    super.key,
  });

  final int earnedThisYear;

  /// The server's yearly limit; zero before the code exists.
  final int yearlyCap;

  /// When the month running now ends, as the household reads a date.
  final String? runningUntilLabel;
  final int monthsWaiting;
  final bool hasReachedCap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final running = runningUntilLabel;
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ReferralCopy.monthsTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.md),
          if (yearlyCap > 0) ...[
            NestStarBurst(
              burst: earnedThisYear,
              child: MonthTokens(earned: earnedThisYear, cap: yearlyCap),
            ),
            const SizedBox(height: NestSpace.md),
            Text(
              ReferralCopy.monthsThisYear(earnedThisYear, yearlyCap),
              style: nest.text.body,
            ),
          ],
          if (earnedThisYear == 0)
            Text(ReferralCopy.noMonthsYet, style: nest.text.bodySecondary),
          if (running != null) ...[
            const SizedBox(height: NestSpace.sm),
            Text(ReferralCopy.runningUntil(running), style: nest.text.body),
          ],
          if (monthsWaiting > 0) ...[
            const SizedBox(height: NestSpace.sm),
            Text(ReferralCopy.waiting(monthsWaiting), style: nest.text.body),
          ],
          if (hasReachedCap) ...[
            const SizedBox(height: NestSpace.md),
            const NestBanner(message: ReferralCopy.capReached),
          ],
        ],
      ),
    );
  }
}
