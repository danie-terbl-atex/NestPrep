import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/referral_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/referral_copy.dart';

/// The way to *give a month, get a month* from the household screen, beside
/// plan and billing (subscriptions ADR-0002).
class ReferralLink extends StatelessWidget {
  const ReferralLink({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: ReferralCopy.openFromHousehold,
        subtitle: ReferralCopy.openFromHouseholdBody,
        leading: const NestIconTile(
          icon: LucideIcons.gift,
          tint: NestTileTint.butter,
        ),
        trailing: const Icon(LucideIcons.chevronRight),
        // Pushed, so back lands where the person was (`FE-17`).
        onTap: () => context.push(ReferralRoute.pathFor(householdId)),
      ),
    );
  }
}
