import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/entitlement.dart';
import '../model/entitlement_status.dart';

/// Which plan the household is on, and the one thing worth knowing about it
/// next — when it renews or ends, a payment the store is retrying, a pause —
/// and who bought it (subscriptions ADR-0001). Every sentence is copy; the
/// date is the household's, already formatted by the screen.
class PlanStatusCard extends StatelessWidget {
  const PlanStatusCard({
    required this.entitlement,
    required this.isPremium,
    required this.untilLabel,
    required this.buyerName,
    super.key,
  });

  final Entitlement entitlement;
  final bool isPremium;

  /// `premiumUntil` as the household reads a date, or null.
  final String? untilLabel;

  /// Who bought it, named, or null when nobody has.
  final String? buyerName;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final detail = _detail();
    final buyer = buyerName;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NestIconTile(
                icon: isPremium
                    ? Icons.workspace_premium_outlined
                    : Icons.home_outlined,
                tint: isPremium ? NestTileTint.accent : NestTileTint.mint,
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(
                child: Text(
                  isPremium ? SubscriptionCopy.premium : SubscriptionCopy.free,
                  style: nest.text.headline,
                ),
              ),
              if (entitlement.isTest)
                const Flexible(
                  child: NestTag(
                    label: SubscriptionCopy.storeTest,
                    tone: NestTagTone.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Text(detail, style: nest.text.body),
          if (buyer != null &&
              entitlement.status != EntitlementStatus.none) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              SubscriptionCopy.managedBy(buyer, entitlement.store),
              style: nest.text.caption,
            ),
          ],
        ],
      ),
    );
  }

  String _detail() {
    switch (entitlement.status) {
      case EntitlementStatus.none:
        return SubscriptionCopy.freeSummary;
      case EntitlementStatus.onHold:
        return SubscriptionCopy.onHold;
      case EntitlementStatus.revoked:
        return SubscriptionCopy.refunded;
      default:
        break;
    }
    final until = untilLabel;
    if (!isPremium || until == null) return SubscriptionCopy.lapsed;
    if (entitlement.status == EntitlementStatus.inGracePeriod) {
      return SubscriptionCopy.graceUntil(until);
    }
    return entitlement.isRenewing
        ? SubscriptionCopy.renewsOn(until)
        : SubscriptionCopy.endsOn(until);
  }
}
