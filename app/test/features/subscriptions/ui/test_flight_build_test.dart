import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/model/test_flight_build.dart';
import 'package:nestprep/features/subscriptions/state/plan_controller.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/plan_screen.dart';
import 'package:nestprep/features/subscriptions/ui/premium_voucher_host.dart';
import 'package:nestprep/shared/copy/premium_voucher_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/fake_premium_vouchers.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// The TestFlight build sells nothing and always offers Premium claims
/// (subscriptions ADR-0014).
void main() {
  late SubscriptionHarness premium;

  const openLabel = 'Open the paywall';

  List<SingleChildWidget> providers() {
    final households = FakeHouseholdRepository();
    addTearDown(households.close);
    return [
      ...premium.providers,
      Provider<HouseholdRepository>.value(value: households),
      ChangeNotifierProvider<FeatureFlagsController>(
        create: (_) => FeatureFlagsController(
          source: FakeFeatureFlagSource(),
          defaultOn: false,
        ),
      ),
    ];
  }

  Future<void> openPaywall(WidgetTester tester, {HouseholdView? view}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      Builder(
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
      providers: providers(),
      view: view,
    );
    await tester.tap(find.text(openLabel));
    await tester.pumpAndSettle();
  }

  setUp(() => debugTestFlightBuild = true);
  tearDown(() {
    debugTestFlightBuild = null;
    debugDefaultTargetPlatformOverride = null;
  });

  test('only a build made with the define is the TestFlight build', () {
    debugTestFlightBuild = null;
    expect(isTestFlightBuild, isFalse);
  });

  testWidgets('the paywall offers no plan, no buy and no restore', (
    tester,
  ) async {
    premium = SubscriptionHarness();
    await openPaywall(tester);

    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.lunchBox)),
      findsOneWidget,
    );
    expect(find.text(SubscriptionCopy.claimTitle), findsOneWidget);
    expect(find.text(SubscriptionCopy.claimAction), findsOneWidget);
    expect(find.text(SubscriptionCopy.subscribe), findsNothing);
    expect(find.text(r'R59.99'), findsNothing);
    expect(find.text(SubscriptionCopy.restore), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('claiming closes the paywall and opens what is waiting', (
    tester,
  ) async {
    premium = SubscriptionHarness();
    premium.vouchers.waiting = [FakePremiumVoucherDirectory.frame];
    premium.inbox.attach(Fixtures.view().viewerUid);
    await openPaywall(tester);

    await tester.tap(find.text(SubscriptionCopy.claimAction));
    await tester.pumpAndSettle();

    expect(find.text(SubscriptionCopy.claimTitle), findsNothing);
    expect(find.text(PremiumVoucherCopy.sheetTitle), findsOneWidget);
  });

  testWidgets('with nothing waiting, claiming starts at the email', (
    tester,
  ) async {
    premium = SubscriptionHarness();
    await openPaywall(tester);

    await tester.tap(find.text(SubscriptionCopy.claimAction));
    await tester.pumpAndSettle();

    expect(find.text(PremiumVoucherCopy.emailLabel), findsOneWidget);
  });

  testWidgets('a helper is told to ask a parent, with nothing to tap', (
    tester,
  ) async {
    premium = SubscriptionHarness();
    await openPaywall(
      tester,
      view: Fixtures.view(viewerUid: Fixtures.thandiUid),
    );

    expect(find.text(SubscriptionCopy.claimAskAParent), findsOneWidget);
    expect(find.text(SubscriptionCopy.claimAction), findsNothing);
  });

  testWidgets('the plan screen has no restore or manage, and offers claims', (
    tester,
  ) async {
    premium = SubscriptionHarness();
    final household = Fixtures.view();
    await pumpScreen(
      tester,
      ChangeNotifierProvider(
        create: (_) => PlanController(
          storeBilling: premium.store,
          purchaseCoordinator: premium.coordinator,
          linkOpener: FakeLinkOpener(),
          viewerMemberId: household.viewerMember?.id,
        ),
        child: const PlanScreen(),
      ),
      providers: providers(),
      view: household,
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(PremiumVoucherCopy.differentEmail),
      200,
    );
    expect(find.text(SubscriptionCopy.seePremium), findsOneWidget);
    expect(find.text(SubscriptionCopy.restore), findsNothing);
    expect(find.text(SubscriptionCopy.manage), findsNothing);
  });

  testWidgets('iOS offers waiting Premium with the cloud switch off', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    premium = SubscriptionHarness();
    premium.vouchers.waiting = [FakePremiumVoucherDirectory.frame];
    await pumpScreen(
      tester,
      const PremiumVoucherHost(child: Text('home')),
      providers: providers(),
    );
    await tester.pumpAndSettle();

    expect(find.text(PremiumVoucherCopy.sheetTitle), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
