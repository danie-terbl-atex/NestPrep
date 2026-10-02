import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';

/// What premium adds, one row each — on the paywall and on the plan screen,
/// so the promise is worded once (`ENG-01`). Rows, not a checklist: nothing
/// here is tappable.
class PremiumBenefits extends StatelessWidget {
  const PremiumBenefits({super.key});

  static const _benefits = [
    (
      Icons.child_care_outlined,
      NestTileTint.guava,
      SubscriptionCopy.benefitChildren,
      SubscriptionCopy.benefitChildrenBody,
    ),
    (
      Icons.insights_outlined,
      NestTileTint.basil,
      SubscriptionCopy.benefitLearning,
      SubscriptionCopy.benefitLearningBody,
    ),
    (
      Icons.checklist_rtl_outlined,
      NestTileTint.butter,
      SubscriptionCopy.benefitPrep,
      SubscriptionCopy.benefitPrepBody,
    ),
    (
      Icons.family_restroom_outlined,
      NestTileTint.lilac,
      SubscriptionCopy.benefitHousehold,
      SubscriptionCopy.benefitHouseholdBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, tint, title, body) in _benefits)
          NestListRow(
            leading: NestIconTile(
              icon: icon,
              tint: tint,
              size: NestSize.avatarMedium,
              iconSize: NestSize.iconMedium,
            ),
            title: title,
            subtitle: body,
          ),
      ],
    );
  }
}
