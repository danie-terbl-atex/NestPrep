import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/purchase_progress.dart';

/// Changing, cancelling and restoring (subscriptions ADR-0001). Only the
/// buyer can change a subscription, from the store they bought it in, so
/// everybody else is told who can instead of being handed a button that
/// opens somebody else's nothing.
class PlanActions extends StatelessWidget {
  const PlanActions({
    required this.progress,
    required this.onManage,
    required this.onRestore,
    required this.onDismiss,
    this.onlyBuyerNote,
    super.key,
  });

  final PurchaseProgress progress;

  /// Null when this viewer cannot manage the subscription here.
  final VoidCallback? onManage;

  /// Said instead of the manage button, when somebody else bought it.
  final String? onlyBuyerNote;
  final VoidCallback onRestore;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final manage = onManage;
    final note = onlyBuyerNote;
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
            onAction: onDismiss,
          ),
          const SizedBox(height: NestSpace.md),
        ],
        if (progress is PurchaseSucceeded) ...[
          NestBanner(
            message: SubscriptionCopy.welcomeBody,
            tone: NestBannerTone.success,
            actionLabel: SubscriptionCopy.done,
            onAction: onDismiss,
          ),
          const SizedBox(height: NestSpace.md),
        ],
        if (manage != null) ...[
          NestButton(
            label: SubscriptionCopy.manage,
            icon: LucideIcons.externalLink,
            variant: NestButtonVariant.outline,
            onPressed: manage,
          ),
          const SizedBox(height: NestSpace.md),
        ] else if (note != null) ...[
          Text(note, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.md),
        ],
        Text(SubscriptionCopy.restoreHint, style: nest.text.caption),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: isRestoring
              ? SubscriptionCopy.restoring
              : SubscriptionCopy.restore,
          icon: LucideIcons.history,
          variant: NestButtonVariant.tonal,
          size: NestButtonSize.medium,
          isLoading: isRestoring,
          onPressed: progress.isBusy ? null : onRestore,
        ),
      ],
    );
  }
}
