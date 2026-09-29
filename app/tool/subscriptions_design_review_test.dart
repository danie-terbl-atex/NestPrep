import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/billing_store.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/subscription_plan.dart';
import 'package:nestprep/features/subscriptions/state/plan_controller.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_sheet.dart';
import 'package:nestprep/features/subscriptions/ui/plan_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_link_opener.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/pump_subscriptions.dart';
import 'review_press.dart';

/// Subscriptions in the design-review press (subscriptions ADR-0001): the
/// paywall opened on a second child, and the plan screen free and on
/// premium, in both themes. Pictures to look at rather than assertions:
/// regenerate with
///
///     flutter test tool/subscriptions_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  const openLabel = 'Mark as a child';

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('paywall-$theme', (tester) async {
      final premium = SubscriptionHarness();
      await captureScreen(
        tester,
        'paywall-$theme',
        brightness: brightness,
        screen: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showPaywall(
                  context,
                  feature: PremiumFeature.additionalChild,
                ),
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
