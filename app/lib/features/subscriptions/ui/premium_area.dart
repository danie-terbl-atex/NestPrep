import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/premium_feature.dart';
import '../state/household_entitlement.dart';
import 'paywall_page.dart';

/// A Premium place (subscriptions ADR-0009): [child] for a household that
/// has Premium, and otherwise the same place shown locked, never hidden.
class PremiumArea extends StatelessWidget {
  const PremiumArea({
    required this.feature,
    required this.child,
    this.title,
    super.key,
  });

  final PremiumFeature feature;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<HouseholdEntitlement>();
    if (entitlement.isPremium) return child;
    return NestScaffold(
      title: title,
      leading: backLeading(context),
      body: switch (entitlement.entitlement) {
        AsyncData() => PremiumLockedView(feature: feature),
        AsyncFailure(:final failure) => NestErrorView(
          message: AppCopy.failure(failure),
          retryLabel: AppCopy.retry,
          onRetry: entitlement.retry,
        ),
        _ => const NestLoadingView(),
      },
    );
  }
}

/// What a locked Premium place says, and the way to it. The body alone, for
/// a tab or a section that already has its own header.
class PremiumLockedView extends StatelessWidget {
  const PremiumLockedView({required this.feature, super.key});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) => NestEmptyView(
    icon: LucideIcons.lock,
    title: SubscriptionCopy.headline(feature),
    message: SubscriptionCopy.pitch(feature),
    actionLabel: SubscriptionCopy.seePremium,
    onAction: () => showPaywall(context, feature: feature),
  );
}

/// Whether the household above [context] has Premium. A place outside the
/// household shell has no entitlement to ask and is treated as locked.
bool hasPremiumIn(BuildContext context) =>
    context.watch<HouseholdEntitlement?>()?.isPremium ?? false;

/// Whether the household above [context] is known to be without Premium,
/// which is when a way in carries a lock. Loading or unreadable is not.
bool isKnownFree(BuildContext context) {
  final entitlement = context.watch<HouseholdEntitlement?>();
  return entitlement != null && entitlement.isKnown && !entitlement.isPremium;
}
