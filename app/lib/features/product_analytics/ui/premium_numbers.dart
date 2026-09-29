import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/weekly_numbers.dart';
import 'beta_number_tile.dart';
import 'beta_tile_grid.dart';

/// A week's premium numbers (product-analytics ADR-0002): how many of the
/// families shown premium bought it, what opened the paywall for each of
/// them, and what *give a month, get a month* did. Counts only — never a
/// family or a person.
class PremiumNumbers extends StatelessWidget {
  const PremiumNumbers({required this.numbers, super.key});

  final WeeklyNumbers numbers;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    const copy = AppCopy.productAnalytics;
    final percent = numbers.conversionRatePercent;
    final triggers = numbers.byTrigger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(copy.premiumTitle, style: nest.text.label),
        const SizedBox(height: NestSpace.md),
        BetaTileGrid(
          tiles: [
            BetaNumberTile(
              label: copy.conversion,
              value: percent == null ? copy.noPaywall : copy.percent(percent),
              detail: percent == null
                  ? null
                  : copy.conversionDetail(
                      bought: numbers.premiumConversions,
                      shown: numbers.paywallFamilies,
                    ),
            ),
            BetaNumberTile(
              label: copy.referrals,
              value: '${numbers.referralsRedeemed}',
              detail: copy.referralsDetail(
                qualified: numbers.referralsQualified,
                months: numbers.referralMonthsGiven,
              ),
            ),
          ],
        ),
        if (triggers.isNotEmpty) ...[
          const SizedBox(height: NestSpace.lg),
          Text(copy.byTriggerTitle, style: nest.text.caption),
          const SizedBox(height: NestSpace.xs),
          for (final trigger in triggers)
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(top: NestSpace.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        copy.triggerName(trigger.feature),
                        style: nest.text.body,
                      ),
                    ),
                    const SizedBox(width: NestSpace.md),
                    Flexible(
                      child: Text(
                        copy.triggerRate(
                          bought: trigger.conversions,
                          shown: trigger.families,
                          percent: trigger.ratePercent,
                        ),
                        style: nest.text.body,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
