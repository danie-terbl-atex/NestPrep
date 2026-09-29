import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/referral_copy.dart';

/// The three steps of *give a month, get a month*, and the small print said
/// plainly — the yearly limit, and that a month waits behind paid time
/// (subscriptions ADR-0002).
class ReferralHowItWorks extends StatelessWidget {
  const ReferralHowItWorks({super.key});

  static const _steps = [
    (Icons.ios_share, ReferralCopy.howShare),
    (Icons.cottage_outlined, ReferralCopy.howJoin),
    (Icons.card_giftcard_outlined, ReferralCopy.howReward),
  ];

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ReferralCopy.howTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.md),
          for (final (index, (icon, step)) in _steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NestIconTile(
                    icon: icon,
                    tint:
                        NestTileTint.values[index % NestTileTint.values.length],
                    size: NestSize.controlSmall,
                    iconSize: NestSize.iconMedium,
                  ),
                  const SizedBox(width: NestSpace.md),
                  Expanded(child: Text(step, style: nest.text.body)),
                ],
              ),
            ),
          Text(ReferralCopy.howFinePrint, style: nest.text.caption),
        ],
      ),
    );
  }
}
