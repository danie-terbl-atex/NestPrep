import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../legal/ui/legal_document_screen.dart';
import '../model/billing_store.dart';
import '../model/purchase_progress.dart';

/// The one button that buys and what is happening while it does. A failure
/// is said in NestPrep's words, never the store's (`FE-09`), and the button
/// cannot be pressed twice (`FE-10`).
class PaywallBuy extends StatelessWidget {
  const PaywallBuy({
    required this.progress,
    required this.canSubscribe,
    required this.onSubscribe,
    required this.onDismissFailure,
    super.key,
  });

  final PurchaseProgress progress;

  /// A plan is on sale and chosen.
  final bool canSubscribe;
  final VoidCallback onSubscribe;
  final VoidCallback onDismissFailure;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    final isBuying = switch (progress) {
      PurchaseInStore() || PurchaseVerifying(isRestore: false) => true,
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
          onPressed: canSubscribe && !progress.isBusy ? onSubscribe : null,
        ),
      ],
    );
  }
}

/// What sits under the offer: restoring an earlier purchase, the terms in
/// plain words and the two documents themselves, which both stores want
/// beside the price.
class PaywallAfterword extends StatelessWidget {
  const PaywallAfterword({
    required this.progress,
    required this.store,
    required this.onRestore,
    super.key,
  });

  final PurchaseProgress progress;
  final BillingStore? store;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final isRestoring = switch (progress) {
      PurchaseVerifying(isRestore: true) => true,
      _ => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestButton(
          label: isRestoring
              ? SubscriptionCopy.restoring
              : SubscriptionCopy.restore,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.medium,
          isLoading: isRestoring,
          onPressed: progress.isBusy ? null : onRestore,
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          SubscriptionCopy.smallPrint(store),
          style: nest.text.caption,
          textAlign: TextAlign.center,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: NestSpace.lg,
          children: [
            NestButton(
              label: LegalCopy.termsTitle,
              variant: NestButtonVariant.link,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: () => context.push(LegalDocumentScreen.termsPath),
            ),
            NestButton(
              label: LegalCopy.privacyTitle,
              variant: NestButtonVariant.link,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: () => context.push(LegalDocumentScreen.privacyPath),
            ),
          ],
        ),
      ],
    );
  }
}
