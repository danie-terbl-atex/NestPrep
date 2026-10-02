import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/paywall_offer.dart';
import '../state/paywall_controller.dart';
import 'paywall_actions.dart';
import 'paywall_plans.dart';

/// The part of the paywall that depends on the server and the store: the
/// plans and the button that buys, in all four states (`FE-08`). Not on sale
/// yet is said plainly and is not an error; a helper is told who can buy.
class PaywallOfferView extends StatelessWidget {
  const PaywallOfferView({required this.controller, super.key});

  final PaywallController controller;

  @override
  Widget build(BuildContext context) {
    return NestAsyncView<PaywallOffer>(
      state: controller.offer,
      isEmpty: (offer) => !offer.isOnSale,
      onRetry: controller.load,
      loadingRows: 2,
      emptyBuilder: (_) => switch (controller.offer) {
        AsyncData(value: PaywallOffer(:final offer))
            when offer.isAvailable && !offer.canBuy =>
          const NestBanner(message: SubscriptionCopy.askAParent),
        _ => const NestEmptyView(
          title: SubscriptionCopy.notYetTitle,
          message: SubscriptionCopy.notYetBody,
          icon: LucideIcons.hourglass,
        ),
      },
      dataBuilder: (context, offer) {
        final choice = offer.choice;
        if (choice == null) return const SizedBox.shrink();
        final isBusy = controller.progress.isBusy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaywallPlans(
              choice: choice,
              selected: controller.selected,
              onSelect: isBusy ? null : controller.select,
            ),
            const SizedBox(height: NestSpace.md),
            PaywallActions(
              progress: controller.progress,
              store: controller.store,
              canSubscribe: controller.selected != null,
              onSubscribe: controller.subscribe,
              onRestore: controller.restore,
              onDismissFailure: controller.acknowledge,
            ),
          ],
        );
      },
    );
  }
}
