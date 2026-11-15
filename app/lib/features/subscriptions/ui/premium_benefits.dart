import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/premium_highlight.dart';
import 'premium_highlight_look.dart';

/// What Premium adds, one row each, on the plan screen — the same areas in
/// the same words as the paywall's cards (`ENG-01`). Nothing here is
/// tappable.
class PremiumBenefits extends StatelessWidget {
  const PremiumBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final highlight in PremiumHighlight.values)
          NestListRow(
            leading: NestIconTile(
              icon: highlight.icon,
              tint: highlight.tint,
              size: NestSize.avatarMedium,
              iconSize: NestSize.iconMedium,
            ),
            title: SubscriptionCopy.highlightTitle(highlight),
            subtitle: SubscriptionCopy.highlightBody(highlight),
          ),
      ],
    );
  }
}
