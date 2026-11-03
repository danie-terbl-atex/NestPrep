import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/premium_voucher_copy.dart';
import '../model/entitlement.dart';
import '../model/grant_source.dart';

class PremiumTimeCard extends StatelessWidget {
  const PremiumTimeCard({
    required this.entitlement,
    required this.now,
    required this.dateLabel,
    super.key,
  });

  final Entitlement entitlement;
  final DateTime now;
  final String Function(DateTime) dateLabel;

  static bool hasTimeWaiting(Entitlement entitlement) =>
      entitlement.daysWaiting.total > 0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final isPaid = entitlement.isPaidAt(now);
    final storeUntil = entitlement.storeUntil;
    final givenUntil = entitlement.givenUntil;
    final isGivenNow = givenUntil != null && entitlement.isGivenOnlyAt(now);
    return NestCard(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NestSpace.xl),
            child: Text(
              PremiumVoucherCopy.timeTitle,
              style: nest.text.cardTitle,
            ),
          ),
          if (isPaid && storeUntil != null)
            NestListRow(
              leading: const NestIconTile(
                icon: LucideIcons.creditCard,
                tint: NestTileTint.basil,
              ),
              title: PremiumVoucherCopy.paidPlan,
              subtitle: PremiumVoucherCopy.until(dateLabel(storeUntil)),
            ),
          if (isGivenNow)
            NestListRow(
              leading: const NestIconTile(icon: LucideIcons.sparkles),
              title: PremiumVoucherCopy.freePremium,
              subtitle: entitlement.daysWaiting.total > 0
                  ? PremiumVoucherCopy.untilWithWaiting(dateLabel(givenUntil))
                  : PremiumVoucherCopy.until(dateLabel(givenUntil)),
            ),
          for (final source in GrantSource.values)
            if (entitlement.daysWaiting.of(source) > 0)
              NestListRow(
                key: ValueKey('premium-time-${source.name}'),
                leading: NestIconTile(
                  icon: switch (source) {
                    GrantSource.referral => LucideIcons.users,
                    GrantSource.frame => LucideIcons.image,
                    GrantSource.code => LucideIcons.gift,
                  },
                  tint: NestTileTint.butter,
                ),
                title: PremiumVoucherCopy.sourceTitle(source),
                subtitle: PremiumVoucherCopy.waiting(
                  source,
                  entitlement.lengthWaiting(source),
                ),
              ),
          if (isPaid)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpace.xl,
                NestSpace.sm,
                NestSpace.xl,
                NestSpace.sm,
              ),
              child: Text(
                PremiumVoucherCopy.waitsForPaid,
                style: nest.text.caption,
              ),
            ),
        ],
      ),
    );
  }
}
