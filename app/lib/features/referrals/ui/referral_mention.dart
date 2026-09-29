import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/referral_copy.dart';

/// *Give a month, get a month*, mentioned where a family is already thinking
/// about premium or about the people in its life — the paywall, the plan
/// screen and the invite step (subscriptions ADR-0002). It only says it and
/// reports the tap; the screen decides whether it is offered and where the
/// tap goes (`FE-03`).
class ReferralMention extends StatelessWidget {
  const ReferralMention({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: EdgeInsets.zero,
      child: NestListRow(
        leading: const NestIconTile(
          icon: Icons.card_giftcard_outlined,
          tint: NestTileTint.peach,
        ),
        title: ReferralCopy.title,
        subtitle: ReferralCopy.mentionBody,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
