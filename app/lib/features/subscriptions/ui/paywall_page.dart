import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/referral_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../household/model/household_view.dart';
import '../../product_analytics/data/paywall_open_recorder.dart';
import '../../referrals/ui/referral_mention.dart';
import '../../referrals/ui/referrals_offered.dart';
import '../data/store_billing.dart';
import '../data/subscription_directory.dart';
import '../model/premium_feature.dart';
import '../model/premium_highlight.dart';
import '../model/purchase_progress.dart';
import '../model/test_flight_build.dart';
import '../state/paywall_controller.dart';
import '../state/premium_voucher_inbox.dart';
import '../state/purchase_coordinator.dart';
import 'highlights_offered.dart';
import 'paywall_actions.dart';
import 'paywall_gallery.dart';
import 'paywall_offer_bar.dart';
import 'premium_highlights.dart';
import 'premium_mark.dart';
import 'premium_voucher_sheet.dart';

/// Offers Premium as a page over everything, opened on the [feature] the
/// person reached for or from the plan screen (subscriptions ADR-0001,
/// ADR-0010). Answers true once the household has Premium.
///
/// Reads what it needs from the caller's context before the page opens, so
/// it works from any screen under the household shell.
Future<bool> showPaywall(
  BuildContext context, {
  required PremiumFeature feature,
}) async {
  final householdId = context.read<HouseholdView>().household.id;
  final directory = context.read<SubscriptionDirectory>();
  final billing = context.read<StoreBilling>();
  final coordinator = context.read<PurchaseCoordinator>();
  final recorder = context.read<PaywallOpenRecorder>();
  // Give a month, get a month is mentioned to family while it is switched
  // on (subscriptions ADR-0002).
  final router = GoRouter.maybeOf(context);
  final onReferral = router != null && referralsOffered(context, listen: false)
      ? () => router.push(ReferralRoute.pathFor(householdId))
      : null;
  final onClaim =
      isTestFlightBuild && context.read<HouseholdView>().permissions.isFamily
      ? () {
          if (!context.mounted) return;
          final inbox = context.read<PremiumVoucherInbox>();
          showPremiumVoucherSheet(
            context,
            startWithEmail: inbox.waiting.isEmpty,
          );
        }
      : null;
  final upgraded = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => PaywallController(
          subscriptionDirectory: directory,
          storeBilling: billing,
          purchaseCoordinator: coordinator,
          paywallOpenRecorder: recorder,
          householdId: householdId,
          feature: feature,
        ),
        child: PaywallPage(onReferral: onReferral, onClaim: onClaim),
      ),
    ),
  );
  return upgraded ?? false;
}

/// The paywall (subscriptions ADR-0010): the brand waves behind it
/// (design-system ADR-0025), photos of what Premium is, the whole Premium
/// map as cards, and the plans with the button that buys docked at the foot.
class PaywallPage extends StatelessWidget {
  const PaywallPage({this.onReferral, this.onClaim, super.key});

  /// Opens *give a month, get a month* once the page has closed; null when
  /// it is not offered to this person.
  final VoidCallback? onReferral;

  /// Opens the claim sheet once the page has closed, in the TestFlight build
  /// only (ADR-0014); null for anybody who is not family.
  final VoidCallback? onClaim;

  /// Past this the dock would take the page, so the offer scrolls with it.
  static const _dockTextScale = 1.3;
  static const _dockMinHeight = 600.0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaywallController>();
    if (controller.progress is PurchaseSucceeded) {
      return _Welcome(
        onDone: () {
          controller.acknowledge();
          Navigator.of(context).pop(true);
        },
      );
    }
    final docks =
        MediaQuery.textScalerOf(context).scale(1) <= _dockTextScale &&
        MediaQuery.sizeOf(context).height >= _dockMinHeight;
    final Widget offerBar = isTestFlightBuild
        ? PaywallClaimBar(
            onClaim: switch (onClaim) {
              final claim? => () {
                Navigator.of(context).pop(false);
                claim();
              },
              null => null,
            },
          )
        : PaywallOfferBar(controller: controller, isSideBySide: docks);
    return NestScaffold(
      backdrop: const NestWaves(),
      leading: NestIconButton(
        icon: LucideIcons.x,
        label: SubscriptionCopy.close,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      bodyPadding: EdgeInsets.zero,
      bottomBar: docks ? NestDock(child: offerBar) : null,
      body: _PaywallBody(
        controller: controller,
        offerBar: docks ? null : offerBar,
        onReferral: onReferral,
      ),
    );
  }
}

class _PaywallBody extends StatelessWidget {
  const _PaywallBody({
    required this.controller,
    required this.offerBar,
    required this.onReferral,
  });

  final PaywallController controller;

  /// The offer, when it scrolls with the page rather than sitting in the dock.
  final Widget? offerBar;
  final VoidCallback? onReferral;

  static const _gutter = EdgeInsets.symmetric(horizontal: NestSpace.gutter);

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final feature = controller.feature;
    final isOnSale = switch (controller.offer) {
      AsyncData(:final value) => value.isOnSale,
      _ => false,
    };
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + NestSpace.xxl,
      ),
      children: [
        NestRiseIn(
          child: PaywallGallery(
            first: PremiumHighlight.of(feature),
            offered: highlightsOffered(context),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        Padding(
          padding: _gutter,
          child: NestRiseIn(
            index: 1,
            child: Column(
              children: [
                const NestTag(
                  label: SubscriptionCopy.paywallLabel,
                  tone: NestTagTone.accent,
                  icon: LucideIcons.sparkles,
                ),
                const SizedBox(height: NestSpace.sm),
                Text(
                  SubscriptionCopy.headline(feature),
                  style: nest.text.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NestSpace.sm),
                Text(
                  SubscriptionCopy.pitch(feature),
                  style: nest.text.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xxl),
        Padding(
          padding: _gutter,
          child: NestRiseIn(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NestSectionHeader(title: SubscriptionCopy.everything),
                const SizedBox(height: NestSpace.md),
                PremiumHighlights(feature: feature),
                const SizedBox(height: NestSpace.sm),
                Text(
                  SubscriptionCopy.wholeHousehold,
                  style: nest.text.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                if (offerBar case final offerBar?) ...[
                  const SizedBox(height: NestSpace.xl),
                  offerBar,
                ],
                if (isOnSale && !isTestFlightBuild) ...[
                  const SizedBox(height: NestSpace.lg),
                  PaywallAfterword(
                    progress: controller.progress,
                    store: controller.store,
                    onRestore: controller.restore,
                  ),
                ],
                if (onReferral case final open?) ...[
                  const SizedBox(height: NestSpace.lg),
                  ReferralMention(
                    onTap: () {
                      Navigator.of(context).pop(false);
                      open();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Where the plans and the button that buys sit in every other build: Premium
/// comes with a frame or a gift, and the way to claim it (ADR-0014).
class PaywallClaimBar extends StatelessWidget {
  const PaywallClaimBar({required this.onClaim, super.key});

  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final claim = onClaim;
    if (claim == null) {
      return const NestBanner(message: SubscriptionCopy.claimAskAParent);
    }
    final nest = NestTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const NestIconTile(
              icon: LucideIcons.gift,
              tint: NestTileTint.butter,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SubscriptionCopy.claimTitle,
                    style: nest.text.bodyStrong,
                  ),
                  Text(
                    SubscriptionCopy.claimBody,
                    style: nest.text.label.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: NestSpace.md),
        NestButton(
          key: const ValueKey('paywall-claim'),
          label: SubscriptionCopy.claimAction,
          icon: LucideIcons.gift,
          onPressed: claim,
        ),
      ],
    );
  }
}

/// The moment it worked: cheered once, then said plainly with one way on.
class _Welcome extends StatefulWidget {
  const _Welcome({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NestCelebration.show(
        context,
        title: SubscriptionCopy.welcomeCheer,
        picture: const PremiumMark(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestScaffold(
      backdrop: const NestWaves(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const NestRiseIn(child: PremiumMark()),
              const SizedBox(height: NestSpace.lg),
              Text(
                SubscriptionCopy.welcomeTitle,
                style: nest.text.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpace.sm),
              Text(
                SubscriptionCopy.welcomeBody,
                style: nest.text.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpace.xxl),
              NestButton(
                label: SubscriptionCopy.done,
                onPressed: widget.onDone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
