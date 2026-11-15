import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/family_entry.dart';
import '../model/food_rules.dart';

/// Recording allergies and medication is Premium (subscriptions ADR-0008):
/// a household without it sees both sections, locked, and what it recorded
/// before is kept but not shown.
bool isHealthLocked(BuildContext context) =>
    !context.watch<HouseholdEntitlement>().isPremium;

/// True once the household has Premium, after the paywall on recording
/// health if it did not.
Future<bool> ensureHealthPremium(BuildContext context) =>
    ensurePremium(context, feature: PremiumFeature.healthProfile);

/// What limits [entry]'s food with the allergies left out: the diet and the
/// school's rule stay free to see.
FoodRules rulesWithoutAllergies(FamilyEntry entry) => FoodRules(
  profile: entry.profile.copyWith(
    allergies: const {},
    otherAllergies: const {},
  ),
  school: entry.school,
);

/// A locked health section's body: that it is Premium, in the section's own
/// place, with the lock that says so to a screen reader.
class HealthLockedNote extends StatelessWidget {
  const HealthLockedNote({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          LucideIcons.lock,
          size: NestSize.iconSmall,
          color: nest.colors.inkTertiary,
          semanticLabel: SubscriptionCopy.lockedHint,
        ),
        const SizedBox(width: NestSpace.sm),
        Expanded(child: Text(message, style: nest.text.bodySecondary)),
      ],
    );
  }
}
