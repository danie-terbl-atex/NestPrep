import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/referral_copy.dart';
import '../model/referral_line.dart';
import '../model/referral_reward.dart';
import '../model/referral_side.dart';
import '../model/referral_status.dart';

/// One referral this household took part in: which side it was on, where it
/// has got to, and what it brought — never who the other family is
/// (subscriptions ADR-0002). The tag repeats the status in a word, so colour
/// is never the only signal (`FE-13`).
class ReferralLineRow extends StatelessWidget {
  const ReferralLineRow({
    required this.line,
    required this.now,
    required this.formatDate,
    super.key,
  });

  final ReferralLine line;

  /// What "now" is — pending past its deadline reads as expired.
  final DateTime now;

  /// An instant as the household reads a date.
  final String Function(DateTime instant) formatDate;

  @override
  Widget build(BuildContext context) {
    final status = line.statusAt(now);
    // The date that matters: the deadline while pending, the day it paid out.
    final instant = switch (status) {
      ReferralStatus.pending => line.qualifyBy,
      ReferralStatus.qualified => line.qualifiedAt,
      ReferralStatus.expired => null,
    };
    final date = instant == null ? '' : formatDate(instant);
    final (subtitle, tag, tone) = switch ((status, line.reward)) {
      (ReferralStatus.pending, _) => (
        ReferralCopy.linePending(date),
        ReferralCopy.tagPending,
        NestTagTone.neutral,
      ),
      (ReferralStatus.qualified, ReferralReward.capped) => (
        ReferralCopy.lineCapped(date),
        ReferralCopy.tagCapped,
        NestTagTone.warning,
      ),
      (ReferralStatus.qualified, _) => (
        ReferralCopy.lineQualified(date),
        ReferralCopy.tagMonth,
        NestTagTone.success,
      ),
      (ReferralStatus.expired, _) => (
        ReferralCopy.lineExpired,
        ReferralCopy.tagExpired,
        NestTagTone.neutral,
      ),
    };
    final isReferrer = line.side == ReferralSide.referrer;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        leading: NestIconTile(
          icon: isReferrer ? Icons.ios_share : Icons.redeem_outlined,
          tint: isReferrer ? NestTileTint.basil : NestTileTint.guava,
        ),
        title: isReferrer
            ? ReferralCopy.lineReferrer
            : ReferralCopy.lineReferred,
        subtitle: subtitle,
        footer: Align(
          alignment: AlignmentDirectional.centerStart,
          child: NestTag(label: tag, tone: tone),
        ),
      ),
    );
  }
}
