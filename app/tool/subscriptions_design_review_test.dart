import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/billing_store.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/subscription_offer.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';
import 'package:nestprep/features/subscriptions/state/plan_controller.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/plan_screen.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_link_opener.dart';
import '../test/support/fake_subscriptions.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/pump_subscriptions.dart';
import 'review_press.dart';

/// Subscriptions in the design-review press (subscriptions ADR-0001): the
/// paywall opened on lunchboxes and on the nanny hub, and the plan screen free and on
/// premium, in both themes. Pictures to look at rather than assertions:
/// regenerate with
///
///     flutter test tool/subscriptions_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  const openLabel = 'Open a locked place';

  testWidgets('paywall-dark-200-percent-text', (tester) async {
    final premium = SubscriptionHarness();
    await captureScreen(
      tester,
      'paywall-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
      screen: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  showPaywall(context, feature: PremiumFeature.lunchBox),
              child: const Text(openLabel),
            ),
          ),
        ),
      ),
      providers: premium.providers,
      emit: () async {
        await tester.pumpAndSettle();
        await tester.tap(find.text(openLabel));
      },
      act: () => tester.drag(find.byType(ListView), const Offset(0, -900)),
    );
  });

  for (final (name, arrange) in <(String, void Function(SubscriptionHarness))>[
    ('paywall-not-in-store-dark', (premium) => premium.store.catalogue = {}),
    (
      'paywall-not-on-sale-dark',
      (premium) => premium.server.answer = SubscriptionOffer.unavailable,
    ),
  ]) {
    testWidgets(name, (tester) async {
      final premium = SubscriptionHarness();
      arrange(premium);
      await captureScreen(
        tester,
        name,
        brightness: Brightness.dark,
        screen: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    showPaywall(context, feature: PremiumFeature.lunchBox),
                child: const Text(openLabel),
              ),
            ),
          ),
        ),
        providers: premium.providers,
        emit: () async {
          await tester.pumpAndSettle();
          await tester.tap(find.text(openLabel));
        },
      );
    });
  }

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    for (final (name, feature) in [
      ('paywall', PremiumFeature.lunchBox),
      ('paywall-nanny-hub', PremiumFeature.nannyHub),
    ]) {
      testWidgets('$name-$theme', (tester) async {
        final premium = SubscriptionHarness();
        await captureScreen(
          tester,
          '$name-$theme',
          brightness: brightness,
          screen: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showPaywall(context, feature: feature),
                  child: const Text(openLabel),
                ),
              ),
            ),
          ),
          providers: premium.providers,
          emit: () async {
            await tester.pumpAndSettle();
            await tester.tap(find.text(openLabel));
          },
        );
      });
    }

    testWidgets('paywall-everything-$theme', (tester) async {
      final premium = SubscriptionHarness();
      await captureScreen(
        tester,
        'paywall-everything-$theme',
        brightness: brightness,
        screen: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    showPaywall(context, feature: PremiumFeature.lunchBox),
                child: const Text(openLabel),
              ),
            ),
          ),
        ),
        providers: premium.providers,
        emit: () async {
          await tester.pumpAndSettle();
          await tester.tap(find.text(openLabel));
        },
        act: () => tester.drag(find.byType(ListView), const Offset(0, -520)),
      );
    });

    testWidgets('paywall-welcome-$theme', (tester) async {
      final premium = SubscriptionHarness();
      await captureScreen(
        tester,
        'paywall-welcome-$theme',
        brightness: brightness,
        screen: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    showPaywall(context, feature: PremiumFeature.lunchBox),
                child: const Text(openLabel),
              ),
            ),
          ),
        ),
        providers: premium.providers,
        emit: () async {
          await tester.pumpAndSettle();
          await tester.tap(find.text(openLabel));
        },
        act: () async {
          await tester.tap(find.text(SubscriptionCopy.subscribe));
          await tester.pump();
          premium.store.report([purchased()]);
        },
      );
    });

    testWidgets('plan-premium-$theme', (tester) async {
      final premium = SubscriptionHarness(
        entitlement: Entitlement(
          premiumUntil: DateTime.utc(2027, 10, 5),
          status: EntitlementStatus.active,
          plan: SubscriptionPlan.yearly,
          store: BillingStore.playStore,
          willRenew: true,
          managedByMemberId: Fixtures.samMemberId,
        ),
      );
      await capturePlan(tester, 'plan-premium-$theme', premium, brightness);
    });

    testWidgets('plan-free-$theme', (tester) async {
      await capturePlan(
        tester,
        'plan-free-$theme',
        SubscriptionHarness(),
        brightness,
      );
    });
  }
}

Future<void> capturePlan(
  WidgetTester tester,
  String name,
  SubscriptionHarness premium,
  Brightness brightness,
) => captureScreen(
  tester,
  name,
  brightness: brightness,
  screen: ChangeNotifierProvider(
    create: (_) => PlanController(
      storeBilling: premium.store,
      purchaseCoordinator: premium.coordinator,
      linkOpener: FakeLinkOpener(),
      viewerMemberId: Fixtures.samMemberId,
    ),
    child: const PlanScreen(),
  ),
  providers: premium.providers,
  emit: () async {},
);
