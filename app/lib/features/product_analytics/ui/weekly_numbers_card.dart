import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/weekly_numbers.dart';
import 'beta_number_tile.dart';
import 'beta_tile_grid.dart';
import 'premium_numbers.dart';

/// One week's three beta numbers on a card (product-analytics ADR-0001).
///
/// The week still running is raised and gives the north star a row of its
/// own; an earlier week sits flat with its three numbers side by side, so the
/// eye lands on now first and can then run down the weeks comparing like with
/// like.
class WeeklyNumbersCard extends StatelessWidget {
  const WeeklyNumbersCard({
    required this.numbers,
    required this.today,
    this.isCurrent = false,
    super.key,
  });

  final WeeklyNumbers numbers;

  /// What "today" is, for saying when the numbers were counted.
  final CalendarDate today;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    const copy = AppCopy.productAnalytics;
    final weekRange = NestDates.weekRange(numbers.weekStart);
    final computedAt = numbers.computedAt;
    final percent = numbers.inviteRatePercent;

    final activeFamilies = BetaNumberTile(
      label: copy.activeFamilies,
      value: '${numbers.activeFamilies}',
      detail: copy.activeFamiliesDetail(numbers.familiesSeen),
      isProminent: isCurrent,
    );
    final others = [
      BetaNumberTile(
        label: copy.lunchPlans,
        value: '${numbers.lunchPlansCreated}',
        detail: copy.lunchPlansDetail(numbers.familiesPlanningLunches),
      ),
      BetaNumberTile(
        label: copy.inviteRate,
        value: percent == null ? copy.noNewFamilies : copy.percent(percent),
        detail: percent == null
            ? null
            : copy.inviteRateDetail(
                inviting: numbers.newFamiliesInvitingAnAdult,
                newFamilies: numbers.newFamilies,
                isStillCounting: !numbers.isInviteCohortComplete,
              ),
      ),
    ];
    final tiles = isCurrent ? others : [activeFamilies, ...others];

    return NestCard(
      variant: isCurrent ? NestCardVariant.raised : NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isCurrent ? copy.thisWeek : weekRange, style: nest.text.title),
          if (isCurrent) Text(weekRange, style: nest.text.caption),
          const SizedBox(height: NestSpace.lg),
          if (isCurrent) ...[
            activeFamilies,
            const SizedBox(height: NestSpace.xl),
          ],
          BetaTileGrid(tiles: tiles),
          // Premium and referrals (product-analytics ADR-0002): always this
          // week, and an earlier week only when there was any.
          if (isCurrent || numbers.hasPremiumActivity) ...[
            const SizedBox(height: NestSpace.xl),
            PremiumNumbers(numbers: numbers),
          ],
          if (computedAt != null) ...[
            const SizedBox(height: NestSpace.lg),
            Text(
              copy.counted(
                NestDates.relative(
                  CalendarDate.fromDateTime(computedAt.toLocal()),
                  today,
                ),
              ),
              style: nest.text.caption,
            ),
          ],
        ],
      ),
    );
  }
}
