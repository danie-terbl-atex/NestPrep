import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/test_flight_build.dart';
import 'package:nestprep/features/subscriptions/state/plan_controller.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/plan_screen.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_household.dart';
import '../test/support/fake_link_opener.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/pump_subscriptions.dart';
import 'review_press.dart';

/// The TestFlight build, which sells nothing (subscriptions ADR-0014): the
/// paywall with *Claim my Premium* where the plans were, and the plan screen
/// without Restore or Manage. Regenerate with
///
///     flutter test tool/testflight_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });
  setUp(() => debugTestFlightBuild = true);
  tearDown(() => debugTestFlightBuild = null);

  List<SingleChildWidget> providers(SubscriptionHarness premium) {
    final households = FakeHouseholdRepository();
    addTearDown(households.close);
    return [
      ...premium.providers,
      Provider<HouseholdRepository>.value(value: households),
    ];
  }

  const openLabel = 'Open';

  Future<void> paywall(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    double textScale = 1,
  }) {
    final premium = SubscriptionHarness();
    return captureScreen(
      tester,
      name,
      brightness: brightness,
      textScale: textScale,
      screen: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showPaywall(context, feature: PremiumFeature.lunchBox),
            child: const Text(openLabel),
          ),
        ),
      ),
      providers: providers(premium),
      emit: () async {},
      act: () => tester.tap(find.text(openLabel)),
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('testflight-paywall-${brightness.name}', (tester) async {
      await paywall(
        tester,
        'testflight-paywall-${brightness.name}',
        brightness: brightness,
      );
    });
  }

  testWidgets('testflight-paywall-dark-200-percent-text', (tester) async {
    await paywall(
      tester,
      'testflight-paywall-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
    );
  });

  testWidgets('testflight-plan-light', (tester) async {
    final premium = SubscriptionHarness();
    final household = Fixtures.view();
    await captureScreen(
      tester,
      'testflight-plan-light',
      view: household,
      screen: ChangeNotifierProvider(
        create: (_) => PlanController(
          storeBilling: premium.store,
          purchaseCoordinator: premium.coordinator,
          linkOpener: FakeLinkOpener(),
          viewerMemberId: household.viewerMember?.id,
        ),
        child: const PlanScreen(),
      ),
      providers: providers(premium),
      emit: () async {},
      act: () => tester.drag(find.byType(ListView), const Offset(0, -400)),
    );
  });
}
