import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/paywall_offer.dart';
import '../state/paywall_controller.dart';
import 'paywall_actions.dart';
import 'paywall_plans.dart';

/// The part of the paywall that depends on the server and the store: the
/// plans and the button that buys, in all four states (`FE-08`), each small
/// enough for the dock. Not on sale yet is said plainly and is not an
/// error; a helper is told who can buy.
class PaywallOfferBar extends StatelessWidget {
  const PaywallOfferBar({
    required this.controller,
    required this.isSideBySide,
    super.key,
  });

  final PaywallController controller;
  final bool isSideBySide;

  @override
  Widget build(BuildContext context) {
    return switch (controller.offer) {
      AsyncLoading() => const NestSkeleton(height: NestSize.controlLarge),
      AsyncFailure(:final failure) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
          ),
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: AppCopy.retry,
            variant: NestButtonVariant.tonal,
            size: NestButtonSize.medium,
            onPressed: controller.load,
          ),
        ],
      ),
      AsyncData(value: PaywallOffer(:final choice?)) when !choice.isEmpty =>
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaywallPlans(
              choice: choice,
              selected: controller.selected,
              onSelect: controller.progress.isBusy ? null : controller.select,
              isSideBySide: isSideBySide,
            ),
            const SizedBox(height: NestSpace.md),
            PaywallBuy(
              progress: controller.progress,
              canSubscribe: controller.selected != null,
              onSubscribe: controller.subscribe,
              onDismissFailure: controller.acknowledge,
            ),
          ],
        ),
      AsyncData(value: PaywallOffer(:final offer))
          when offer.isAvailable && !offer.canBuy =>
        const NestBanner(message: SubscriptionCopy.askAParent),
      AsyncData() => const _NotYet(),
    };
  }
}

class _NotYet extends StatelessWidget {
  const _NotYet();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Row(
      children: [
        const NestIconTile(
          icon: LucideIcons.hourglass,
          tint: NestTileTint.butter,
        ),
        const SizedBox(width: NestSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(SubscriptionCopy.notYetTitle, style: nest.text.bodyStrong),
              Text(
                SubscriptionCopy.notYetBody,
                style: nest.text.label.copyWith(
                  color: nest.colors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
