import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/billing_store.dart';
import '../model/purchase_progress.dart';

/// The paywall's foot: the one button that buys, what is happening while it
/// does, restoring an earlier purchase, and the terms in plain words. A
/// failure is said in NestPrep's words, never the store's (`FE-09`), and the
/// button cannot be pressed twice (`FE-10`).
class PaywallActions extends StatelessWidget {
  const PaywallActions({
    required this.progress,
    required this.store,
    required this.canSubscribe,
    required this.onSubscribe,
    required this.onRestore,
    required this.onDismissFailure,
    super.key,
  });

  final PurchaseProgress progress;
  final BillingStore? store;

  /// A plan is on sale and chosen.
  final bool canSubscribe;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;
  final VoidCallback onDismissFailure;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final progress = this.progress;
    final isBusy = progress.isBusy;
    final isBuying = switch (progress) {
      PurchaseInStore() || PurchaseVerifying(isRestore: false) => true,
      _ => false,
    };
    final isRestoring = switch (progress) {
      PurchaseVerifying(isRestore: true) => true,
      _ => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (progress case PurchaseFailed(:final failure)) ...[
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: SubscriptionCopy.notNow,
            onAction: onDismissFailure,
          ),
          const SizedBox(height: NestSpace.md),
        ],
        if (progress is PurchaseAwaitingApproval) ...[
          const NestBanner(message: SubscriptionCopy.awaitingApproval),
          const SizedBox(height: NestSpace.md),
        ],
        NestButton(
          label: switch (progress) {
            PurchaseInStore() => SubscriptionCopy.openingStore,
            PurchaseVerifying(isRestore: false) => SubscriptionCopy.unlocking,
            _ => SubscriptionCopy.subscribe,
          },
          icon: LucideIcons.award,
          isLoading: isBuying,
          onPressed: canSubscribe && !isBusy ? onSubscribe : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: isRestoring
              ? SubscriptionCopy.restoring
              : SubscriptionCopy.restore,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.medium,
          isLoading: isRestoring,
          onPressed: isBusy ? null : onRestore,
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          SubscriptionCopy.smallPrint(store),
          style: nest.text.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
